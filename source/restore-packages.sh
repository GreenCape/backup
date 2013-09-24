#!/bin/sh

# @see http://wiki.ubuntuusers.de/Paketverwaltung/Tipps#Paketliste-zur-Wiederherstellung-erzeugen

# Checking for user - this operation needs root permissions
if [ "$(whoami)" != 'root' ]
then
    echo "You have no permission to run $0 as non-root user. Use sudo!" >&2
    exit 1;
fi

# Get option arguments
has_error="no"
directory="backup"

while getopts ":d" opt
do
    case $opt in
        d)  # directory
            directory=$OPTARG
            ;;
        \?) # unknown
            has_error="yes"
            ;;
    esac
done

# Error check
if [ "$has_error" == "yes" ]
then
    echo ""
    echo "Usage: "$(basename $0)" [-d directory]"
    echo ""
    echo "  -d directory   The target directory with the package dump."
    echo "                 If ommitted, 'backup' is used."
    echo "                 If the path is relative, i.e. not starting with a slash '/',"
    echo "                 it is relative to the current directory."
    echo ""
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
