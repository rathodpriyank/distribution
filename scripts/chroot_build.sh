#!/bin/bash

### BEGIN INIT INFO
# Provides:          chroot_build.sh
# Required-Start:
# Required-Stop:
# X-Stop-After:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starting the second order debootstrap
# Description:       As states above
#				- It will start the second order debootstrap to process and
#				   install the features.
#				- By provding this feature, it will make sure everything required
#				  to work with OpenQ820 is configured properly.
#				- Author : Priyank Rathod <rathodpriyank@gmail.com>
### END INIT INFO

# generic defines
_source_list=/etc/apt/sources.list
_sysctl_conf=/etc/sysctl.conf
_secure_tty=/etc/securetty
_etc_fstab=/etc/fstab
_libfirmware_dir=/lib/firmware
_firmware_dir=/firmware
_android_dir=/system
_init_scripts=/etc/init.d
_sshd_config=/etc/ssh/sshd_config
_rcs_dir=/etc/rc7.d
_hostname="Debian"
_hostfile0=/etc/hostname
_hostfile1=/etc/hosts
_gen_node=ttyS0			# This needs to be changed as per board serial config
_gen_consol=/dev/${_gen_node}
_kmsg=/dev/kmsg
_tty_node=/dev/tty
_root_password=debian
_getty_dir=/etc/systemd/system/getty.target.wants
_getty_default_file=getty@tty1.service
_getty_desired_file=getty@${_gen_node}.service

second_stage_debootstrap()
{
	# second stage bootstraping
	if [ -d /debootstrap ]; then
		echo "Starting Second stage debootstrap..."
		/debootstrap/debootstrap --second-stage
	else
		echo "No Second stage bootstrap required ..."
	fi

	# change the sshd configuration
	sed -i 's|#PasswordAuthentication yes|PasswordAuthentication yes|g' ${_sshd_config}

	# mounting others partitions
	mount -o bind dev /dev
	mount -t proc proc /proc
	mount -t devpts devpts /dev/pts
	mount -t sysfs sys /sys

	# changing the hostname
	if [ "${_hostname}" = "`grep -s ${_hostname} ${_hostfile0}`" ]; then
		echo "Hostname is as expected ${_hostname}"
	else
		echo ${_hostname} > ${_hostfile0}
		echo "127.0.0.1  ${_hostname}" > ${_hostfile1}
	fi

	# adding the update source of debian jessie
	if [ ! -s ${_source_list} ]; then
		echo "Updating some source for updates"
		echo "deb http://ftp.debian.org/debian/ jessie main contrib non-free" >> ${_source_list}
		echo "deb http://ftp.debian.org/debian/ jessie-updates main contrib non-free" >> ${_source_list}
		echo ""  >> ${_source_list}
		echo "deb-src http://ftp.debian.org/debian/ jessie main contrib non-free" >> ${_source_list}
		echo "deb-src http://ftp.debian.org/debian/ jessie-updates main contrib non-free" >> ${_source_list}
	fi

	# changing the output of log level
	echo "Change the console output to minimum"
	sed -i 's|#kernel.printk = 3 4 1 3|kernel.printk = 1 1 1 1|g' ${_sysctl_conf}

	# creating the node for kernel logs
	if [ ! -c ${_kmsg} ]; then echo "Creating kmsg node"; mknod ${_kmsg} c 1 11; fi

	# updating the node information for the very first node
	sed -i 's|TTYVTDisallocate=yes|TTYVTDisallocate=no|g'  ${_getty_dir}/${_getty_default_file}

	# creating tty0...tty6
	#for i in 2 3 4 5 6 7 8 9 ;
	#do
	#	if [ ! -c ${_tty_node}$i ]; then
	#		mknod ${_tty_node}$i c 5 $i
	#		chown root:tty ${_tty_node}$i
	#		echo "Creating the getty service for ${_tty_node}$i"
	#		cp ${_getty_dir}/${_getty_default_file} ${_getty_dir}/getty@tty$i.service
	#		sed -i "s|DefaultInstance=tty1|DefaultInstance=tty$i|g" ${_getty_dir}/getty@tty$i.service
	#	fi
	#done

	# creating the entries for qualcomm specific device nodes
	if [ "${_gen_node}" = "`grep -s ${_gen_node} ${_secure_tty}`" ]; then
		echo "Found everything as expected"
	else
		echo "Injecting the Generic ports"
		echo "# Generic secure port" >> ${_secure_tty}
		echo "${_gen_node}" >> ${_secure_tty}
	fi

	# creating the node for qualcomm specific serial port
	if [ ! -c ${_gen_consol} ]; then
		echo "Creating ${_gen_consol} node and supplying necessary permissions and ownerships"
		mknod ${_gen_consol} c 237 0
		chmod 664 ${_gen_consol}
		chown root:dialout ${_gen_consol}
	fi

	# creating the login prompt entry for qualcomm serial device
	if [ ! -f ${_getty_dir}/${_getty_desired_file} ]; then
		echo "Creating the getty service for ${_gen_node}"
		cp ${_getty_dir}/${_getty_default_file} ${_getty_dir}/${_getty_desired_file}
		sed -i 's|DefaultInstance=tty1|DefaultInstance=ttyHSL0|g' ${_getty_dir}/${_getty_desired_file}
	fi

	# creating the system link for the custom init.d scripts added by us
	if [ ! -d ${_rcs_dir} ]; then
		mkdir ${_rcs_dir}
		cd ${_rcs_dir}
		if [ ! -f S02resizeme ]; then
			ln -s ../init.d/resizeme.sh S02resizeme
		fi
		cd -
	fi

	# maks sure that sudo can be used by everyone or any new user
	chmod 4755 /usr/bin/sudo

	# changing the password of root ( at present adding debian as a root user)"
	passwd -d root							# just removing root password

	get_info=`cat /etc/group | grep "debian"`
	if [[ -z $get_info ]]; then
		adduser debian --gecos "Debian User" --disabled-password
		echo "debian:${_root_password}" | chpasswd
		sudo adduser debian sudo
	else
		echo "User already present"
	fi

	# updating the rc scripts
	echo "Enabling the rc.d scripts"
	update-rc.d resizeme.sh defaults
	update-rc.d resizeme.sh enable

	# unmounting some system partitions, so that it wan't create problem later on
	umount /dev/pts
	umount /proc
	umount /sys
	umount /dev
	umount -a

	# removing my self in the end so that no one repeats this again
	echo "Removing myself"
	#rm -rf $0
	echo "Performing the graceful exit (probably I will never reach here)"
}

main()
{
	second_stage_debootstrap
}

main
exit 0
