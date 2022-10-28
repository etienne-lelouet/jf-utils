#!/bin/bash
#===============================================================================
#
#          FILE:  create_symlinks.sh
# 
#         USAGE:  ./create_symlinks.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  realpath
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:   (Etienne Le Louët (admin@jeanpierre.moe), 
#       COMPANY: jeanpierre.moe 
#       VERSION:  1.0
#       CREATED:  10/28/22 15:20:41 CEST
#      REVISION:  ---
#===============================================================================

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


export DRY_RUN=false
export SEDEXPR=""
export FILTEREXPR=""
export VERBOSE=false
export YES=false
export SOURCEFILELIST=""
export EXIT_ON_SYMLINK_ERROR=false
export NO_DRY_RUN=false
TMP=$(getopt -n create_symlinks.sh -o '' --longoptions 'verbose,no-dry-run,exit-on-symlink-error,dry-run,yes,sedexpr:,filterexpr:' -- "$@")

if [ $? != 0 ];
then
	echo_error "Terminating..."
	cleanup_and_exit 1
fi

eval set -- "$TMP"

while true; do
	case "$1" in
		--dry-run)
			export DRY_RUN=true
			shift 1
			;;
		--exit-on-symlink-error)
			export EXIT_ON_SYMLINK_ERROR=true
			shift 1
			;;
		--no-dry-run)
			export NO_DRY_RUN=true
			shift 1
			;;
		--sedexpr)
			export SEDEXPR=$2
			shift 2
			;;
		--filterexpr)
			export FILTEREXPR=$2
			shift 2
			;;
		--verbose)
			export VERBOSE=true
			shift 1
			;;
		--yes)
			export YES=true
			shift 1
			;;
		--)
			shift 1
			break
			;;
		*)
			echo_error "Internal error !"
			cleanup_and_exit 
	esac
done

if ! [ -z ${1+x} ];
then
	if ! [ -d "$1" ];
	then
		echo_error "Source dir $1 does not exist"
		cleanup_and_exit 1
	fi

	if ! [ -r "$1" ];
	then
		echo_error "Source dir $1 is not readable"
		cleanup_and_exit 1
	fi
else
	echo_error "Requires one positional arg as source dir dir"
	cleanup_and_exit 1
fi
export SRCDIR=$(realpath "$1")
shift

if ! [ -z ${1+x} ];
then
	export DESTDIR="$1"
else
	export DESTDIR=$(pwd)
fi

if [ -d "$DESTDIR" ];
then
	if ! [ -w "$DESTDIR" ];
	then
		echo_error "Dest dir $DESTDIR is not writeable"
		cleanup_and_exit 1
	fi
else
	if ! mkdir -p "$DESTDIR";
	then
		echo_error "Cannot create destination dir $DESTDIR"
		cleanup_and_exit 1
	fi
	if ! [ -w "$DESTDIR" ];
	then
		rm -rf "$DESTDIR"
		echo_error "Dest dir $DESTDIR is not writeable"
		cleanup_and_exit 1
	fi
	rm -rf "$DESTDIR"
fi
export DESTDIR="$(realpath "$DESTDIR")"
if [ $VERBOSE = true ];
then
	echo "DRY_RUN_ONLY ? $DRY_RUN_ONLY"
	echo "SEDEXPR : $SEDEXPR"
	echo "FILTEREXPR : $FILTEREXPR"
	echo "SRCDIR : $SRCDIR"
	echo "DESTDIR : $DESTDIR"
fi

SOURCEFILELIST=$(mktemp)

if [ -n "$FILTEREXPR" ];
then
	find "$SRCDIR" -maxdepth 1 -type f -regextype 'posix-extended' -regex "$FILTEREXPR">"$SOURCEFILELIST"
else
	find "$SRCDIR" -maxdepth 1 -type f>"$SOURCEFILELIST"	
fi

if [ $NO_DRY_RUN = false ];
then

	while read -r SOURCEFILE
	do
		LINK_NAME="$(basename "$SOURCEFILE")"
		if [ -n "$SEDEXPR" ];
		then
			LINK_NAME="$(echo "$LINK_NAME" | sed -nE "$SEDEXPR")"
		fi
		LINK_NAME_ABS="$DESTDIR/$LINK_NAME"

		echo -e "Will create link named ${GREEN}$LINK_NAME_ABS${NC} for file ${GREEN}$SOURCEFILE${NC}"

		if [ -f "$LINK_NAME_ABS" ];
		then
			echo_warning "$LINK_NAME_ABS already exists"
		fi

	done<"$SOURCEFILELIST"
fi

if [ $DRY_RUN = true ];
then
	cleanup_and_exit 0
fi
if [ $NO_DRY_RUN = false ];
then

	read -p "Create links ? [y]es, [n]o " -r
	echo
	if [[ $REPLY =~ ^[Nn]$ ]]; then
    		echo "Quitting..."
    		cleanup_and_exit 0
	fi
fi

if ! mkdir -p "$DESTDIR";
then
	echo_error "unable to create $DESTDIR"
	cleanup_and_exit 1
fi
# save stdin in FD 3
exec 3<&0
while read -r SOURCEFILE
do
	LINK_NAME="$(basename "$SOURCEFILE")"
	if [ -n "$SEDEXPR" ];
	then
		LINK_NAME=$(echo "$LINK_NAME" | sed -nE "$SEDEXPR")
	fi
	LINK_NAME_ABS="$DESTDIR/$LINK_NAME"
	if [ -f "$LINK_NAME_ABS" ];
	then
		if [ $YES = false ];
		then
			echo_warning "$LINK_NAME_ABS already exists"
			while true;
			do
				# We don't want to read the answer in the current loop stdin, which is the filelist
				read -p "Overwrite $LINK_NAME_ABS ? [y]es, [n]o, [a]ll : " -r <&3
				echo		
				if [[ $REPLY =~ ^[Nn]$ ]]; then
					break;
				elif [[ $REPLY =~ ^[Aa]$ ]]; then
					export YES=true
					rm -rf "$LINK_NAME_ABS"
					create_symlink "$SOURCEFILE" "$LINK_NAME_ABS"
					break;
				elif [[ $REPLY =~ ^[Yy]$ ]]; then
					rm -rf "$LINK_NAME_ABS"
					create_symlink "$SOURCEFILE" "$LINK_NAME_ABS"
					break;
				else 
					echo_error "Did not undersdand answer."
				fi
			done
		fi
	else
		create_symlink "$SOURCEFILE" "$LINK_NAME_ABS"
	fi
done<"$SOURCEFILELIST"

rm -rf "$SOURCEFILELIST"

