#!/bin/bash -e
#		This script does everything you imagine to build debian builds.
#		But it is worth to wait till it is finalised
#
#
#
#		Author : Priyank Rathod <rathodpriyank@gmail.com>

# Taking all arguments as an input
args="$@"

# performing basic necessary things
_home=`pwd`
_whome=`whoami`
_normal_user="intrinsyc"
_core=`nproc`
DATE=$(date "+%Y.%m.%d-%H.%M.%S")

# getting some colorful information.
source ${_home}/logger.sh

# variables used by the system;
_clean=
_bversion=jessie
_build_kernel=
_build_dist=
_create_package=
_install_dependencies=

# some signature check files
_isDebootstrapPresent=`apt-cache policy debootstrap | grep Installed:`
_isQemuDebootstrapPresent=`apt-cache policy qemu-utils | grep Installed:`
_isQemuAarm64Present=`apt-cache policy qemu-user-static | grep Installed:`
_isDTCPresent=`apt-cache policy device-tree-compiler | grep Installed:`
_pkg_sign_file=./.signature

# list of folders used by this script so its better they be there
_build_dir=${_home}/../binaries
_tmp_dir=/tmp/system-img
_tmp_disk=/tmp/disk
_target_dir=${_home}/../${_bversion}-arm64
_dl_dir=${_home}/dl
# this directories will be present already or created dynanmically
_src_dir=${_home}/../source_packages
_skl_dir=${_dl_dir}/skales
_scipt_dir=${_src_dir}/scripts
_patch_dir=${_src_dir}/patches
_kn_dir=${_home}/../kernel
_initramfs_dir=${_src_dir}/initramfs
_dtb_dir=${_kn_dir}/arch/arm64/boot/dts/qcom
_linaro_toolchain_dir=${_dl_dir}/linaro-toolchain

# list of files & binaries used by this script
_chroot_script=chroot_build.sh
_def_bash=/bin/bash
_flash_script=${_build_dir}/flashall
_keyring_location=/usr/share/keyrings
_keyring_name=debian-archive-keyring
_keyring_name_wExt=${_keyring_name}.gpg
_debootstrap=/usr/sbin/debootstrap
_qemu_aarch64=/usr/bin/qemu-aarch64-static
_qemu_debootstrap=/usr/sbin/qemu-debootstrap
_kn_img=${_kn_dir}/arch/arm64/boot/Image
_initramfs_img=${_build_dir}/initramfs.igz
_dtb_img=${_dtb_dir}/dt.img
_linaro_manifest=${_linaro_toolchain_name}/gcc-linaro-5.3-2016.02-manifest.txt

# list of website used by this script
_online_source=http://ftp.debian.org/debian
_repo_location=${_online_source}
_linaro_toolchain_url=https://releases.linaro.org/components/toolchain/binaries/latest-5/aarch64-linux-gnu
_linaro_toolchain_name=gcc-linaro-5.3-2016.02-x86_64_aarch64-linux-gnu
_linaro_toolchain_ver=${_linaro_toolchain_name}.tar.xz
_skales_tool=git://codeaurora.org/quic/kernel/skales

# target file system options 
_fs_size=512	# This is in MB
_fs_name=${_build_dir}/system-${_bversion}-${DATE}.img

# this option is always present in every script; indeed it is helpful
usage()
{
	# this is the main usage script used to build the overall system
	echo -e "\n${BOLD}Help${ENDING}:\tThis script is responsbile for package fetching from the debian repositories"
	echo -e "\tIt also requies sudo access, ${RED}don't${ENDING} forget to add sudo infront of the script"
	echo -e "\tIf you do not pass any options to it, by default it will create the jessie unclean build\n"
	echo -e "\t${BOLD}Option${ENDING}: -c|--clean\t\t\tTo clean eveything for this project"
	echo -e "\t\t-f|--file-system\t\tTo build the File System"
	echo -e "\t\t-d|--default\t\t\tTo build the distribution with default options"
	echo -e "\t\t\t\t\t\t - Uncleaned File system with kernel and dependencies"
	echo -e "\t\t-i|--install-dependencies\tTo install the dependencies"
	echo -e "\t\t-k|--kernel\t\t\tTo build the kernel"
	echo -e "\t\t-p|--package\t\t\tTo create the distribution package"
	echo -e "\t\t-h|--help\t\t\tTo show this screen\n"
	echo -e "${BOLD}Example Usage${ENDING}:\t${GREEN}sudo $0 <option> <version>"
	echo -e "\t\t\t ${RED}or${ENDING}"${GREEN}
	echo -e "\t\tsudo $0 <version> <option>"
	echo -e "\t\tsudo $0 -d=jessie \t\t\t${YELLOW}(Build jessie dist.)${GREEN}"
	echo -e "\t\tsudo $0 -d=jessie --clean \t\t${YELLOW}(Build jessie as a clean build)${GREEN}"
	echo -e "\t\tsudo $0 -d=jessie -i \t\t${YELLOW}(Build jessie along with installing dependencies)"${GREEN}
	echo -e "\t\tsudo $0 -d=jessie -c -p \t\t${YELLOW}(Build jessie as a clean build with package)${ENDING}"
}

#information screen.
info_screen()
{
	logme_cyan "Starting the build for ${_bversion} distribution along with kernel" 
	logme_cyan "The time stamp for the build artifacts : $RED$DATE"
	logme_cyan "This script will do the following things"
	logme_cyan "(1) install_keyring \t\t[1m]"
	logme_cyan "(2) install_dependencies \t\t[5m]"
	logme_cyan "(3) check_and_create_dirs \t\t\t[1m]"
	logme_cyan "(4) get_toolchain \t\t[10m]"
	logme_cyan "(5) kn_build \t\t\t[20m]"
	logme_cyan "(6) build_rootfs \t\t\t[30-45m]"
	logme_cyan "(7) cp_build \t\t\t[2m]"
	logme_cyan "Sit back and relax, there is too much to do"
	logme_red "${BOLD}Note: ${CYAN}Time Shown here are just an approximation, it may vary\n
				\t\tvary from system to system and on different approaches \n
				\t\tselected while starting the build\n "
	sleep 5
}

# This will create the basic list of requried directory before the beginning
check_and_create_dirs()
{
	# list of directories needs to be created if not present. 
	_dir_list="${_build_dir} ${_tmp_dir} ${_tmp_disk} ${_target_dir} ${_dl_dir}"
	for i in ${_dir_list}; 
	do
		if [ ! -d $i ]; then
			mkdir -p $i
			logme_green "Creating "$i" directory" 
		else
			logme_cyan "$i is already present"
		fi
	done
}

# installing and adding the debian archive keyrings
install_keyring()
{
	# installing the keyring if it is not installed
	if [ ! -f ${_keyring_location}/${_keyring_name_wExt} ]; then
		logme_red "Installing the keyring, as it is not present"
		apt-get install -y ${_keyring_name}
		apt-key add ${_keyring_location}/${_keyring_name_wExt}
	else
		logme_green "Keyring is already present"
	fi
}

install_dependencies()
{
	# checking for the debootstrap binary, if not install it
	if [ -z "${_isDebootstrapPresent}" ]; then
		logme_red "Installing the ${_debootstrap}, as it is not present"
		apt-get -y install debootstrap 
	else
		logme_green "${_debootstrap} is already present"
	fi

	# checking for the qemu-debootstrap binary, if not install it
	if [ -z "${_isQemuDebootstrapPresent}" ]; then
		logme_red "Installing the ${_qemu_debootstrap}, as it is not present"
		apt-get -y install qemu-utils qemu 
		apt-get -y build-dep qemu
	else
		logme_green "${_qemu_debootstrap} is already present"
	fi
	
	# checking for the qemu-debootstrap for ARM64 binary, if not install it
	if [ -z "${_isQemuAarm64Present}" ]; then
		logme_red "Installing the ${_qemu_aarch64}, as it is not present"
		apt-get -y install qemu-user-static
	else
		logme_green "${_qemu_aarch64} is already present"
	fi
	
	# checking for the device tree compiler, if not present, it will be installed
	if [ -z "${_isDTCPresent}" ]; then
		logme_red "Installing the device-tree-compiler, as it is not present"
		 apt-get -y install device-tree-compiler
	else
		logme_green "device-tree-compiler is already present"
	fi
}

create_package_list()
{
	# list of packages for the target device.
	_packages1="openssh-server,stress-ng,ntp,udhcpc,vim,sudo"
	_packages2="bluetooth,bluez,ethtool,pciutils"
	_packages="${_packages1},${_packages2}"
}

first_stage_debootstrap()
{
	# creating the list of packages for target device 
	logme_yellow "Creating the list of packages for target"
	create_package_list
	
	# Starting the process to build rootfs from here
	logme_green "Starting to sync repo from ${_repo_location}"
	debootstrap --keyring ${_keyring_location}/${_keyring_name_wExt} \
		--arch=arm64 --exclude=debfoster --foreign --include=${_packages} \
		${_bversion} ${_target_dir} ${_repo_location}
	
	# copying the qemu binary to make sure chroot works 	
	logme_green "Copying ${_qemu_aarch64} required to chroot"
	cp ${_qemu_aarch64} ${_target_dir}/usr/bin/

	# copying the scripts to start second stage debootstrap and more
	logme_green "Copying scripts from ${_scipt_dir} to target"
	cp ${_scipt_dir}/* ${_target_dir}/etc/init.d/

	# we will transfer the control from here for further processing	
	logme_cyan "Changing root to ${_target_dir}"
	chroot ${_target_dir} ${_def_bash} -c "/etc/init.d/chroot_build.sh"
}

create_empty_fs()
{
	dd if=/dev/zero of=${_fs_name} bs=1M count=${_fs_size}
	logme_green "Converting to ext4 file package"
	echo y | mkfs.ext4 -q ${_fs_name}
	#expect "${_fs_name} is not a block special device.\nProceed anyway? (y,n)"
	#send -- "y\r"
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

# Getting the toolchain from the *-*-*-*-*-*-*-*-* Internet.
get_toolchain()
{
	if [ ! -f ${_dl_dir}/${_linaro_toolchain_ver} ]; then
		wget ${_linaro_toolchain_url}/${_linaro_toolchain_ver} -P ${_dl_dir}	
		if [ $? -ne 0 ]; then
			logme_red "Download failed .... "
			logme_magenta "Cleaning the mess ... "
			rm -rf ${_dl_dir}/*
		fi
	else
		logme_green "${_linaro_toolchain_ver} is present, only need to extract"
	fi

	if [ ! -d ${_linaro_toolchain_dir} ]; then
		logme_green "Toolchain is not present at ${_linaro_toolchain_dir}"
		tar xvf ${_dl_dir}/${_linaro_toolchain_ver} -C .
		mv ${_linaro_toolchain_name} ${_linaro_toolchain_dir}
		wget ${_linaro_toolchain_url}/${_linaro_toolchain_ver}.asc -P ${_linaro_toolchain_dir}
	else
		logme_green "Toolchain is present at ${_linaro_toolchain_dir}"
	fi
}

get_skales()
{
	if [ ! -d ${_skl_dir} ]; then
		logme_green "Getting the skales from ${_skales_tool} to ${_skl_dir}"
		git clone ${_skales_tool} ${_skl_dir}
		if [ $? = 0 ]; then
			logme_green "Downloaded skales in ${_skl_dir}"
		else
			logme_red "Skale download failed from ${_skales_tool}"
		fi
	fi
}

get_repo()
{
	if [[ -z `which repo` && ! -d ${_dl_dir}/bin ]]; then
		mkdir ${_dl_dir}/bin
		curl https://storage.googleapis.com/git-repo-downloads/repo > ${_dl_dir}/bin/repo
		chmod a+x ${_dl_dir}/bin/repo
	else
		logme_green "repo is present in the system, hence not updating it"
	fi
}
				
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

# This function is only called when trap is triggered; 
# this is only for cleaning up the mess which is left in between processes
clean_up()
{
	logme_red "Cleaning up everything I can ... :)"
	logme_red "Removing ${_build_dir}"
	rm -rf ${_build_dir}
	unmount_fs || echo "Unmounting of FS failed"
	unmount_iso || echo "Unmounting of iso failed"
	exit
}

parse_me()
{
	for i in $args 
	do
		arg1=$(echo ${i} | cut -d'=' -f1)
		arg2=$(echo ${i} | cut -d'=' -f2)
		case "$arg1" in
			-c|--clean)
						logme_green "Setting the cleaning parameter"
						_clean=y;
						;;
			-f|--file-system)	
						logme_green "Setting File System as ${arg2}"
						echo ${_bversion}
						_bversion=${arg2}
						_build_dist=y;
						;;
			-i|--install-dependencies)
						logme_green "Setting option to install dependencies"
						_install_dependencies=y;
						;;
			-k|--kernel)
						logme_green "Setting option to build kernel"
						_build_kernel=y;
						;;
			-p|--package)
						logme_green "Creating the package for internal release"
						_create_package=y;
						;;
			-h|--help)	
						logme_green "Triggering the help screen"
						usage
						exit
						;;								
			-d|--default)
						_clean=n;
						_bversion=jessie
						_install_dependencies=y;
						_build_kernel=y;
						_build_dist=y;
						_create_package=y;
						logme_green "Default option, no clean build for kernel or distribution"
						;;
			*)			
						exit
						;;
		esac
	done
}

main()
{
	if [ "${_whome}" != "root" ] ; then
		usage
		exit
	fi

	# parsing utility to parse the command line arguements
	parse_me

	# this will make sure each folder is present, if not it will create it
	check_and_create_dirs
	
	if [ "xy" = "x${_install_dependencies}" ]; then
		# Installing the keyring
		install_keyring
		# Installing dependencies
		install_dependencies
		# get the toolchain, if it is not present
		get_toolchain
		# get skales if it is not present
		get_skales
		# get repo if it is not present
		get_repo
	fi
	
	if [[ "xy" = "x${_build_kernel}" && \
		  "xy" = "x${_build_dist}" && \
		  "xy" = "x${_create_package}" ]]; then
		info_screen
	fi
	
	if [ "xy" = "x${_build_kernel}" ]; then
		kn_build		# building the kernel
	fi

	if [ "xy" = "x${_build_dist}" ]; then
		build_rootfs	# building rootfs
	fi

	if [ "xy" = "x${_create_package}" ]; then
		cp_build
		create_flashall
		gen_checksum
	fi
	
	# reverting the permissions as a normal user currenrly intrinsyc
	chown -Rv ${_normal_user}:${_normal_user} ../* > /dev/null
}

# I need some trapping here to cleanup :)
trap clean_up SIGINT SIGTERM

main 
exit 0
