#!/bin/bash
#===============================================================================
#
#          FILE:  utils.sh
# 
#         USAGE:  ./utils.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:   (), 
#       COMPANY:  
#       VERSION:  1.0
#       CREATED:  11/29/22 15:30:56 CET
#      REVISION:  ---
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function echo_error() {
	echo -e "${RED}$1${NC}" >&2
}

function echo_warning() {
	echo -e "${YELLOW}$1${NC}" >&2
}

function cleanup_and_exit() {
	if [ -n "$SOURCEFILELIST" ];
	then
		if [ -f "$SOURCEFILELIST" ];
		then
			rm -f "$SOURCEFILELIST"
		fi
	fi
	exit $1
}

function create_symlink() {
	
	if ln -s "$1" "$2";
	then
		echo -e "Created link named ${GREEN}$2${NC} to file ${GREEN}$1${NC}"
	else
		echo_error "Failed to create link named $1 for file $2"
		if [ $EXIT_ON_SYMLINK_ERROR = true ];
		then
			cleanup_and_exit 1
		fi
	fi
}

