#!/bin/bash -e
#		This script does everything you imagine to build debian/ubuntu builds.
#		
#
#
#       Filename: generate_rootfs.sh
#       Usage   : This script is used to build the distributions, 
#                   - It will generate the rootfs for the final system. 
#		Author  : Priyank Rathod <rathodpriyank@gmail.com>

create_package_list()
{
	# list of packages for the target device.
	_packages="openssh-server,stress-ng,ntp,udhcpc,vim,sudo"
	_packages="${_packages},bluetooth,bluez,ethtool,pciutils"
	_packages="${_packages},lightdm,xfce4"
}

first_stage_debootstrap()
{
	# creating the list of packages for target device 
	logme_yellow "Creating the list of packages for target"
	create_package_list
	
	# Starting the process to build rootfs from here
	logme_green "Starting to sync repo from ${_repo_location}"
	sudo debootstrap --keyring ${_keyring_location}/${_keyring_name_wExt} \
		--arch=arm64 --exclude=debfoster --foreign --include=${_packages} \
		${_bversion} ${_target_dir} ${_repo_location}
	
	# copying the qemu binary to make sure chroot works 	
	logme_green "Copying ${_qemu_aarch64} required to chroot"
	sudo cp ${_qemu_aarch64} ${_target_dir}/usr/bin/

	# copying the scripts to start second stage debootstrap and more
	logme_green "Copying scripts from ${_chroot_script} to target"
	sudo cp ${_chroot_script} ${_target_dir}/etc/init.d/

	# we will transfer the control from here for further processing	
	logme_cyan "Changing root to ${_target_dir}"
	sudo chroot ${_target_dir} ${_def_bash} -c "/etc/init.d/chroot_build.sh"
}

create_empty_fs()
{
    _fs_size_byte=`sudo du -d0 ${_target_dir} | cut -f1`
    _fs_size=`expr ${_fs_size_byte} / 1024 + 100`
	dd if=/dev/zero of=${_fs_name} bs=1M count=${_fs_size}
	logme_green "Converting to ext4 file package"
	echo y | mkfs.ext4 -q ${_fs_name}
}

mount_fs()
{	
	if [ ! -d ${_tmp_dir} ]; then
		mkdir ${_tmp_dir}
	fi
	logme_green "Mounting to a temp location"
	sudo mount -t ext4 ${_fs_name} ${_tmp_dir}
	sync
}

transfer_image_data()
{
	logme_green "Just transferring everytime, everything"
	sudo cp -r --preserve=links ${_target_dir}/* ${_tmp_dir}/
	sync
}

unmount_fs()
{
	sync
	logme_red "Unmounting the ${_tmp_dir} ..."
	sudo umount ${_tmp_dir}
	logme_red "Removing ${_tmp_dir} ..."
	sudo rm -rf ${_tmp_dir}
}

build_rootfs()
{
	# Clean/Remove the directory if clean option is enabled
	if [ xy = "x${_clean}" ]; then
		logme_red "Removing ${_target_dir}"
		rm -rf ${_target_dir}
	fi
	
	# first stage of boot strapping process starts here, do everytime
	first_stage_debootstrap
	
	# create the file system
	if [ ! -f ${_fs_name} ]; then
		logme_red "Creating empty file package"
		create_empty_fs
	else
		logme_green "File package is alredy present"
	fi

	# now need to mount the file system	
	mount_fs
	
	# transfer from target to the system image (mounted path) 
	transfer_image_data
	
	# I think I did almost everything so unmounting the file system
	unmount_fs
}
