#!/bin/bash -e
#		This script does everything you imagine to build debian/ubuntu builds.
#		
#
#
#       Filename: common.sh
#       Usage   : This script is used to supoprt the main build.sh. 
#                   - This will have all the necessary varibles
#
#		Author  : Priyank Rathod <rathodpriyank@gmail.com>


# Taking all arguments as an input
export args="$@"

# common variables
export _whome=`whoami`
export _core=`nproc`
export DATE=$(date "+%Y.%m.%d-%H.%M.%S")

# variables used by the system;
export _clean=
export _bversion=jessie
export _build_kernel=
export _build_dist=
export _create_package=
export _install_dependencies=

# list of folders used by this script so its better they be there
export _build_dir=${_home}/binaries
export _tmp_dir=/tmp/system-img
export _target_dir=${_home}/${_bversion}-arm64
export _dl_dir=${_home}/dl
export _tools_dir=${_home}/tools
export _skl_dir=${_tools_dir}/skales
export _kn_dir=${_home}/../kernel
export _dtb_dir=${_kn_dir}/arch/arm64/boot/dts/qcom
export _initramfs_dir=${_home}/initramfs
export _linaro_toolchain_dir=${_home}/linaro-toolchain


# list of files & binaries used by this script
export _chroot_script=${_home}/scripts/chroot_build.sh
export _def_bash=/bin/bash
export _flash_script=${_build_dir}/flashall
export _kn_img=${_kn_dir}/arch/arm64/boot/Image
export _initramfs_tmp=${_build_dir}/initramfs.cpio
export _initramfs_img=${_build_dir}/initramfs.img
export _dtb_img=${_dtb_dir}/dt.img
export _linaro_manifest=${_linaro_toolchain_name}/gcc-linaro-5.3-2016.02-manifest.txt

# list of website used by this script
export _online_source=http://ftp.debian.org/debian
export _repo_location=${_online_source}
export _linaro_toolchain_url=https://releases.linaro.org/components/toolchain/binaries/latest-5/aarch64-linux-gnu
export _linaro_toolchain_name=gcc-linaro-5.3-2016.02-x86_64_aarch64-linux-gnu
export _linaro_toolchain_ver=${_linaro_toolchain_name}.tar.xz
export _skales_tool=git://codeaurora.org/quic/kernel/skales

# busybox
export _busybox_ver=1.25.0
export _busybox=busybox-${_busybox_ver}
export _busybox_url=https://busybox.net/downloads/${_busybox}.tar.bz2
export _busybox_dir=${_tools_dir}/${_busybox}

# target file system options 
export _fs_size=512	# This is in MB
export _fs_name=${_build_dir}/system-${_bversion}-${DATE}.img
