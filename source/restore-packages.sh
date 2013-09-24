#!/bin/bash

usage () {
    echo ""
    echo "Usage: "$(basename $0)" [options]"
    echo ""
    echo "  -d directory | --directory=directory"
    echo "                 The backup directory with the package dump."
    echo "                 If ommitted, '$directory' is used."
    echo "                 If the path is relative, i.e. not starting with a slash '/',"
    echo "                 it is relative to the current directory."
    echo "  -h | --help    Show this messsage"
    echo ""
}

# Get option arguments
has_error="no"
directory="packages.backup.d"

INPUT=$(getopt -n "$0" -o d:h --long "directory:,help" -n "GreenCape Package Restore" -- "$@")
if [ $? -ne 0 ]
then
    exit 1
fi
eval set -- "$INPUT"

while true
do
    case "$1" in
        -d|--directory)
            directory=$2
            shift 2
            ;;
        -h|--help)
            usage
            break
            ;;
        --)
            shift
            break
            ;;
        *) # unknown
            has_error="yes"
            shift
            break
            ;;
    esac
done

# Checking for user - this operation needs root permissions
if [ "$(whoami)" != 'root' ]
then
    echo "You have no permission to run "$(basename $0)" as non-root user. Use sudo!" >&2
    exit 1;
fi

# Error check
if [ "$has_error" == "yes" ]
then
    usage
    exit 1
fi

# Ensure presence
if [ "${directory:0:1}" != "/" ]
then
    directory=$(pwd)"/"$directory
fi
if ! [[ -e $directory ]]
then
    echo "Unable to locate package dump. Directory '"$directory"' not found." >&2
    exit 1;
fi

# Sync the source list
cp $directory"/"sources.list /etc/apt/sources.list.d/restore.list

# Import the trusted keys
apt-key add $directory"/"trusted-keys.gpg
apt-get update

# Install packages
xargs -a $directory"/packages.list" apt-get install

# Restore package states
xargs -a $directory"/package-states-auto" apt-mark auto
xargs -a $directory"/package-states-manual" apt-mark manual
