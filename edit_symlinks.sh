#!/bin/bash
#===============================================================================
#
#          FILE:  edit_symlinks.sh
# 
#         USAGE:  ./edit_symlinks.sh 
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

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/utils.sh"

export SRCDIR="$(pwd)"
export DRY_RUN=false
export SEDEXPR=""
export NAMEFILTEREXPR=""
export CONTENTFILTEREXPR=""
export VERBOSE=false
export YES=false
export SOURCEFILELIST=""
export EXIT_ON_SYMLINK_ERROR=false
export NO_DRY_RUN=false

TMP=$(getopt -n edit_symlinks.sh -o '' --longoptions 'verbose,no-dry-run,exit-on-symlink-error,dry-run,yes,sedexpr:,namefilterexpr:,contentfilterexpr:,sourcedir:' -- "$@")

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
		--contentfilterexpr)
			export CONTENTFILTEREXPR=$2
			shift 2
			;;
		--namefilterexpr)
			export NAMEFILTEREXPR=$2
			shift 2
			;;
		--sourcedir)			
			if ! [ -d "$1" ];
			then
				echo_error "Source dir $2 does not exist"
				cleanup_and_exit 1
			fi
			if ! [ -r "$1" ];
			then
				echo_error "Source dir $1 is not readable"
				cleanup_and_exit 1
			fi
			export SRCDIR=$(realpath "$2")
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
	export NEEDLE="$1"
else
	echo_error "Requires one positional arg as needle"
	cleanup_and_exit 1
fi

shift

if ! [ -z ${1+x} ];
then
	export NEWBASEDIR="$1"
else	
	echo_error "Requires one positional arg as new dest"
	cleanup_and_exit 1
fi

SOURCEFILELIST=$(mktemp)

if [ -n "$NAMEFILTEREXPR" ];
then
	find "$SRCDIR" -type l -name "$FILTEREXPR">"$SOURCEFILELIST"
else
	find "$SRCDIR" -type l > "$SOURCEFILELIST"
fi



if [ $NO_DRY_RUN = false ];
then

	while read -r SOURCEFILE
	do
		CURDEST="$(readlink "$SOURCEFILE")"
		if [ -n "$CONTENTFILTEREXPR" ];
		then
			if echo "$CURDEST" | grep "$CONTENTFILTEREXPR";
			then
				echo "$CURDEST filtered"
				continue
			fi
		fi

		NEWDEST="$(echo "$CURDEST" | sed -n "s|$NEEDLE|$NEWBASEDIR|p")"
		if [ -f "$NEWDEST" ] || [ -d "$NEWDEST" ];
		then
			echo "editing $SOURCEFILE to point to $NEWDEST"
		else
			echo_error "New destination $NEWDEST for $CURDEST does not exist"
			cleanup_and_exit 1
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


while read -r SOURCEFILE
do
	CURDEST="$(readlink "$SOURCEFILE")"
	NEWDEST="$(echo "$CURDEST" | sed -n "s|$NEEDLE|$NEWBASEDIR|p")"
	ln -s -f "$NEWDEST" "$SOURCEFILE"
	if [ $? != 0 ];
	then
		echo_error "ln -s -f $NEWDEST $SOURCEFILE failed"
		cleanup_and_exit 1
	fi
	if [ -f "$NEWDEST" ] || [ -d "$NEWDEST" ];
	then
		echo "edited $SOURCEFILE to point to $NEWDEST"
	else
		echo_error "New destination $NEWDEST for $CURDEST does not exist"
		cleanup_and_exit 1
	fi
done<"$SOURCEFILELIST"

