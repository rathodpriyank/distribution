#!/bin/bash -e
#		This script does everything you imagine to build debian/ubuntu builds.
#		
#
#
#       Filename: build.sh
#       Usage   : This script is used to build the distributions, 
#                  It contains various options 
#		Author  : Priyank Rathod <rathodpriyank@gmail.com>

# Exporting the home location to all
export _home=`pwd`

# Sourcing some scripts before any start
source ${_home}/scripts/includes.sh

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

# This function is only called when trap is triggered; 
# this is only for cleaning up the mess which is left in between processes
clean_up()
{
	logme_red "Cleaning up everything I can ... :)"
	logme_red "Removing ${_build_dir}"
	rm -rf ${_build_dir}
	unmount_fs || echo "Unmounting of FS failed"
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
        logme_green "Installing dependencies"
	fi
	
	if [ "xy" = "x${_build_dist}" ]; then
        logme_green "Selecting the distribution"
	fi

	if [ "xy" = "x${_create_package}" ]; then
        logme_green "Trying to create the package"
	fi
}

# I need some trapping here to cleanup :)
trap clean_up SIGINT SIGTERM

main 
exit 0
