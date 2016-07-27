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
export _build_dir=${_home}/../binaries
export _tmp_dir=/tmp/system-img
export _tmp_disk=/tmp/disk
export _target_dir=${_home}/../${_bversion}-arm64
export _dl_dir=${_home}/dl
# this directories will be present already or created dynanmically
export _src_dir=${_home}/../source_packages
export _skl_dir=${_dl_dir}/skales
export _scipt_dir=${_src_dir}/scripts
export _patch_dir=${_src_dir}/patches
export _kn_dir=${_home}/../kernel
export _initramfs_dir=${_src_dir}/initramfs
export _dtb_dir=${_kn_dir}/arch/arm64/boot/dts/qcom
export _linaro_toolchain_dir=${_dl_dir}/linaro-toolchain

# list of files & binaries used by this script
export _chroot_script=chroot_build.sh
export _def_bash=/bin/bash
export _flash_script=${_build_dir}/flashall
export _kn_img=${_kn_dir}/arch/arm64/boot/Image
export _initramfs_img=${_build_dir}/initramfs.igz
export _dtb_img=${_dtb_dir}/dt.img
export _linaro_manifest=${_linaro_toolchain_name}/gcc-linaro-5.3-2016.02-manifest.txt

# list of website used by this script
export _online_source=http://ftp.debian.org/debian
export _repo_location=${_online_source}
export _linaro_toolchain_url=https://releases.linaro.org/components/toolchain/binaries/latest-5/aarch64-linux-gnu
export _linaro_toolchain_name=gcc-linaro-5.3-2016.02-x86_64_aarch64-linux-gnu
export _linaro_toolchain_ver=${_linaro_toolchain_name}.tar.xz
export _skales_tool=git://codeaurora.org/quic/kernel/skales

# target file system options 
export _fs_size=512	# This is in MB
export _fs_name=${_build_dir}/system-${_bversion}-${DATE}.img
