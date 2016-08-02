#!/bin/bash -e
#		This script does everything you imagine to build debian/ubuntu builds.
#		
#
#
#       Filename: kernel_config.sh
#       Usage   : This script is used to supoprt the main build.sh
#                   - It will generate the kernel for the target device
#
#		Author  : Priyank Rathod <rathodpriyank@gmail.com>


# performing basic necessary things
patch_me()
{
	for d in `ls ${_patch_dir}`
	do  
		if [[ ! `patch -R -p0 --dry-run < ${_patch_dir}/$d` ]]; then
			logme_yellow "Applying $d"
	    	patch -p1 -N < ${_patch_dir}/$d		
	    else
	    	logme_green "No need to apply the "$d""
		fi
	done
}

# Used to build the kernel with the default config file
kn_build()
{

	if [ ! -d ${_kn_dir} ]; then
		logme_red "Kernel is not present, hence not doing anthing"
		return
	fi

	# Clean/Remove the directory if clean option is enabled
	cd ${_kn_dir}
	if [ xy = "x${_clean}" ]; then
		logme_red "Cleaning the kernel"
		make clean;	
	fi
	
	if [ -d ${_linaro_toolchain_dir} ]; then
		export ARCH=arm64
		export CROSS_COMPILE=${_linaro_toolchain_dir}/bin/aarch64-linux-gnu-
		logme_green "Exported $ARCH and $CROSS_COMPILE"
	else
		logme_red "Compiler is not installed, It is required to build kernel"
		logme_red "Use following command to install it,"
		logme_yellow "$0 -i"
		last_cmd=`history |tail -n2 |head -n1| cut -d' ' -f4| sed 's|[0-9]*||g'`
		logme_red "or you may use ${last_cmd} adding "-i" option to it"
		logme_yellow "Such as ${last_cmd} -i"
		exit
	fi
	#patch_me		# TODO : This requires fix
	make msm_el_defconfig
	make -j${_core} 
	make modules
	cd ${_home}
}
