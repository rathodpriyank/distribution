#!/bin/bash -e
#		This script does everything you imagine to build debian/ubuntu builds.
#		
#
#
#       Filename: install_dependencies.sh
#       Usage   : This script is used to build the distributions, 
#                   - It will install the required and defined dependencies.
#		Author  : Priyank Rathod <rathodpriyank@gmail.com>

_keyring_location=/usr/share/keyrings
_keyring_name=debian-archive-keyring
_keyring_name_wExt=${_keyring_name}.gpg
_debootstrap=/usr/sbin/debootstrap
_qemu_aarch64=/usr/bin/qemu-aarch64-static
_qemu_debootstrap=/usr/sbin/qemu-debootstrap
_isDebootstrapPresent=`which debootstrap`
_isQemuDebootstrapPresent=`which qemu-debootstrap`
_isQemuAarm64Present=`which qemu-aarch64-static`
_isDTCPresent=`apt-cache policy device-tree-compiler | grep Installed:`
_pkg_sign_file=./.signature

# installing and adding the debian archive keyrings
install_keyring()
{
	# installing the keyring if it is not installed
	if [ ! -f ${_keyring_location}/${_keyring_name_wExt} ]; then
		logme_red "Installing the keyring, as it is not present"
		sudo apt-get install -y ${_keyring_name}
		sudo apt-key add ${_keyring_location}/${_keyring_name_wExt}
	else
		logme_green "Keyring is already present"
	fi
}

install_dependencies()
{
	# checking for the debootstrap binary, if not install it
	if [ "${_debootstrap}" != "${_isDebootstrapPresent}" ]; then
		logme_red "Installing the ${_debootstrap}, as it is not present"
		sudo apt-get -y install debootstrap
	else
		logme_green "${_debootstrap} is already present"
	fi

	# checking for the qemu-debootstrap binary, if not install it
	if [ "${_qemu_debootstrap}" != "${_isQemuDebootstrapPresent}" ]; then
		logme_red "Installing the ${_qemu_debootstrap}, as it is not present"
		sudo apt-get -y install qemu-utils qemu
		sudo apt-get -y build-dep qemu
	else
		logme_green "${_qemu_debootstrap} is already present"
	fi
	
	# checking for the qemu-debootstrap for ARM64 binary, if not install it
	if [ "${_qemu_aarch64}" != "${_isQemuAarm64Present}" ]; then
		logme_red "Installing the ${_qemu_aarch64}, as it is not present"
		sudo apt-get -y install qemu-user-static
	else
		logme_green "${_qemu_aarch64} is already present"
	fi
	
	# checking for the device tree compiler, if not present, it will be installed
	if [ -z "${_isDTCPresent}" ]; then
		logme_red "Installing the device-tree-compiler, as it is not present"
		sudo apt-get -y install device-tree-compiler
	else
		logme_green "device-tree-compiler is already present"
	fi
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
		mkdir  ${_tools_dir}/bin
		curl https://storage.googleapis.com/git-repo-downloads/repo >  ${_tools_dir}/bin/repo
		chmod a+x  ${_tools_dir}/bin/repo
	else
		logme_green "repo is present in the system, hence not updating it"
	fi
}
