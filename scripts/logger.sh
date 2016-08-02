#!/bin/bash -e
#		This script does everything you imagine to build debian/ubuntu builds.
#		
#
#
#       Filename: logger.sh
#       Usage   : This script is used to supoprt the main build.sh. 
#                   - This will help to generate log file in the current 
#                     directory.
#                   - It will also help the user to log in the file, with 
#                     different colour options to log and display
#
#		Author  : Priyank Rathod <rathodpriyank@gmail.com>

# some localization
UNDER='\e[4m'
BOLD='\e[1m'
ITALICS='\e[3m'
RED='\e[31;1m'
GREEN='\e[32;1m'
YELLOW='\e[33;1m'
BLUE='\e[34;1m'
MAGENTA='\e[35;1m'
CYAN='\e[36;1m'
WHITE='\e[37;1m'
ENDING='\e[0m'

_log_dir=${_home}/logs
_log_file=${_log_dir}/log-${DATE}.txt

# Just making sure the file is there always before beginning. 
if [ ! -d ${_log_dir} ]; then
	mkdir ${_log_dir}
	touch ${_log_file}
fi

# here is universal logger
logme_red()
{
	echo -e "`date +'%b %e %R '` $RED"$@"$ENDING" | tee -a ${_log_file}
}

logme_green()
{
	echo -e "`date +'%b %e %R '` $GREEN"$@"$ENDING" | tee -a  ${_log_file}
}

logme_yellow()
{
	echo -e "`date +'%b %e %R '` $YELLOW"$@"$ENDING" | tee -a  ${_log_file}
}

logme_blue()
{
	echo -e "`date +'%b %e %R '` $BLUE"$@"$ENDING" | tee -a  ${_log_file}
}

logme_cyan()
{
	echo -e "`date +'%b %e %R '` $CYAN"$@"$ENDING" | tee -a  ${_log_file}
}

logme_magenta()
{
	echo -e "`date +'%b %e %R '` $MAGENTA"$@"$ENDING" | tee -a  ${_log_file}
}

logme()
{
	echo -e "`date +'%b %e %R '` $WHITE"$@"$ENDING" | tee -a  ${_log_file}
}

