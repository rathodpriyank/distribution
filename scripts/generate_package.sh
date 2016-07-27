#!/bin/bash -e
#		This script does everything you imagine to build debian/ubuntu builds.
#		
#
#
#       Filename: install_dependencies.sh
#       Usage   : This script is used to build the distributions, 
#                   - It will generate the final package.
#		Author  : Priyank Rathod <rathodpriyank@gmail.com>

# to create the package for final use
cp_build()
{
	# Capture the current date/time to make sure
	# we are consistent when creating images.
	logme_green "Creating the initramfs"
	initramfs_build
	logme_green "Creating the device tree package"
	${_skl_dir}/dtbTool -o ${_dtb_img} -s 2048  ${_dtb_dir}
	logme_green "Creating the final package for the device"
	${_skl_dir}/mkbootimg --base 0 --kernel ${_kn_img} --ramdisk ${_initramfs_img} \
	--output ${_build_dir}/boot-${DATE}.img \
	--dt ${_dtb_img} --pagesize "2048" --base "0x80080000" \
	--cmdline "root=/dev/sda9 rootfstype=ext4 rw console=ttyHSL0,115200n8"
	logme_yellow "Yeah, I finished everything what I said ... "
}

create_flashall()
{
	rm -rf ${_flash_script}
	echo -e "#!/bin/bash" >> ${_flash_script}
	echo -e "echo -e \"Flashing the boot-${DATE}.img\" " >> ${_flash_script}
	echo -e "fastboot flash boot boot-*.img" >> ${_flash_script}
	echo -e "echo -e \"Flashing the system-${_bversion}-${DATE}.img\" " >> ${_flash_script}
	echo -e "fastboot flash userdata system-*.img" >> ${_flash_script}
	echo -e "fastboot reboot" >> ${_flash_script}
	chmod +x ${_flash_script}
}

gen_checksum()
{
	logme_cyan "Generating the checksum for the binaries"
	echo -e "List of files in this folder with checksum" >> ${_build_dir}/checksum
	md5sum ${_build_dir}/* >> ${_build_dir}/checksum
	sed -i 's|'${_build_dir}'/||g' ${_build_dir}/checksum
}
