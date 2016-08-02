#!/bin/sh -e

### BEGIN INIT INFO
# Provides:          resizeme.sh
# Required-Start:
# Required-Stop:
# X-Stop-After:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: extending the size of partition
# Description:       As states above
#				- It extends the smaller flashed partitions to its maximum limit
#				- By doing this, flashing time can be reduced and at the first mount
#				  the device will be extended to its maximum limit.
#
#				- Author : Priyank Rathod <rathodpriyank@gmail.com>
### END INIT INFO

_file_name=$0
YELLOW='\e[33;1m'
ENDING='\e[0m'
sucess1=
sucess2=

# lock files and location
_lock_dir=/var/opt
_lock_fs=${_lock_dir}/.resize.lock

# get information
_get_partition=`cat /proc/cmdline | cut -d "=" -f 4 | cut -d " " -f 1`
_resize=`which resize2fs`

resize_me()
{

	echo "Starting resizing the mounted partition"
	${_resize} ${_get_partition}
	if [ $? = 0 ]; then
		return 0
	fi
}

case "$1" in
	start)
			udhcpc
			# resizing the file system
			if [ ! -f ${_lock_fs} ]; then
				echo "Resizing the mounted partition completed : ${YELLOW}Successfully" ${ENDING}
				resize_me
				if [ $? = 0 ]; then
					touch ${_lock_fs}
				fi
			else
				echo "${YELLOW}${_lock_fs} is present, hence not resizing${ENDING}"
			fi
			;;
	*)
			echo "Usage: /etc/init.d/resizeme.sh {start}"
			exit 1
			;;
esac

exit 0
