#!/bin/bash -e
#		This script does everything you imagine to build debian/ubuntu builds.
#		
#
#
#       Filename: includes.sh
#       Usage   : This script is used to build the distributions, 
#                   - It will be used to as a include script.
#		Author  : Priyank Rathod <rathodpriyank@gmail.com>


_scripts_dir=${_home}/scripts
source ${_scripts_dir}/common.sh
source ${_scripts_dir}/generate_initramfs.sh
source ${_scripts_dir}/generate_kernel.sh
source ${_scripts_dir}/generate_package.sh
source ${_scripts_dir}/generate_rootfs.sh
source ${_scripts_dir}/install_dependencies.sh
source ${_scripts_dir}/logger.sh
