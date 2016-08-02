#!/bin/bash -e
#		This script does everything you imagine to build debian/ubuntu builds.
#		
#
#
#       Filename: generate_initramfs.sh
#       Usage   : This script is used to supoprt the main build.sh. 
#                   - This will generate the initramfs for the target device
#
#		Author  : Priyank Rathod <rathodpriyank@gmail.com>


get_busybox()
{
	# if tar is not present, downloading it
	if [ ! -f ${_dl_dir}/${_busybox}.tar.bz2 ]; then
		wget ${_busybox_url} -P ${_dl_dir}
		if [ $? -ne 0 ]; then
			logme_red "Download failed .... "
			logme_magenta "Cleaning the mess ... "
			rm -rf ${_dl_dir}/*
		fi
	fi

	# extracting busybox here
	if [ ! -d ${_dl_dir}/${_busybox} ]; then
		logme_green "Extracting the busybox"
		tar xvfj ${_dl_dir}/${_busybox}.tar.bz2 -C ${_tools_dir}
		# need to compile it using the toolchain, same as kernel
		if [ $? = 0 ]; then
			logme_green "Extracted succesfully, Now Compiling it"
			cd ${_tools_dir}/${_busybox}
			make defconfig
			make ARCH=arm64 CROSS_COMPILE=${_linaro_toolchain_dir}/bin/aarch64-linux-gnu-
		fi
	else
		logme_green "${_busybox} is present, I guess it is compiled"
	fi
}

initramfs_build()
{
	# Clean/Remove the directory if clean option is enabled
	if [ xy = "x${_clean}" ]; then
		logme_red "Cleaning the initramfs"
		rm -rf ${_initramfs_img}
	fi

	if [ ! -d ${_busybox_dir} ]; then
		get_busybox
	fi
	
	if [ ! -d ${_build_dir} ]; then
		mkdir ${_build_dir}
	fi

	# create our initramfs build dir skeleton
	if [ ! -d ${_initramfs_dir} ]; then
		mkdir -p ${_initramfs_dir}/work/{bin,sbin,etc,proc,sys,newroot}
		if [ $? = 0 ]; then
			logme_green "All directories are being created"
		fi
	fi

	if [ ! -d ${_initramfs_dir}/work ]; then
		logme_cyan "Copying the init"
		mkdir -p ${_initramfs_dir}/work
		cp ${_scipt_dir}/init_for_initramfs work/init
	fi

	if [ ! -d ${_initramfs_dir}/work/etc/ ]; then
		logme_cyan "Just creating mdev config"
		mkdir -p ${_initramfs_dir}/work/etc/
		touch ${_initramfs_dir}/work/etc/mdev.conf
	fi

	# copy the busybox binary
	if [ ! -d ${_initramfs_dir}/work/bin/ ]; then
		logme_cyan "Copying the busybox"
		mkdir -p ${_initramfs_dir}/work/bin/
		cp ${_busybox_dir}/busybox ${_initramfs_dir}/work/bin/
	fi

	#converting to the executable
	touch ${_initramfs_dir}/work/init
	chmod +x ${_initramfs_dir}/work/init

	# Starting to create a package from here
	find ${_initramfs_dir}/work/ | cpio -H newc -o > ${_initramfs_tmp}
	cat ${_initramfs_tmp} | gzip > ${_initramfs_img}
	rm -rf ${_initramfs_tmp}
}
