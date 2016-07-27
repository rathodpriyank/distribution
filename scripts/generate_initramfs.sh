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


initramfs_build()
{
	# Clean/Remove the directory if clean option is enabled
	if [ xy = "x${_clean}" ]; then
		logme_red "Cleaning the initramfs"
		rm -rf ${_initramfs_img}
	fi
	
	# create our initramfs build dir.
	if [ ! -d ${_initramfs_dir} ]; then
		mkdir ${_initramfs_dir}
	fi

	cd ${_initramfs_dir}/
	if [ ! -d work/etc/ ]; then
		mkdir -p work/{bin,sbin,etc,proc,sys,newroot}
		touch work/etc/mdev.conf
	fi
	#converting to the executable
	touch work/init
	chmod +x work/init
	# Starting to create a package from here
	find ./work/ | cpio -H newc -o  > initramfs.cpio
	cat initramfs.cpio | gzip > ${_initramfs_img}
}

