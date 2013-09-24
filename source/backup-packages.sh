#!/bin/bash

# @see http://wiki.ubuntuusers.de/Paketverwaltung/Tipps#Paketliste-zur-Wiederherstellung-erzeugen

# Checking for user - this operation needs root permissions
if [ "$(whoami)" != 'root' ]
then
    echo "You have no permission to run $0 as non-root user. Use sudo!" >&2
    exit 1;
fi

# Get option arguments
has_error="no"
directory="packages.backup.d"

INPUT=$(getopt -n "$0" -o d: --long "directory:" -n "GreenCape Package Backup" -- "$@")
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

# Error check
if [ "$has_error" == "yes" ]
then
    echo ""
    echo "Usage: "$(basename $0)" [-d directory]"
    echo ""
    echo "  -d directory   The target directory for the package dump."
    echo "                 If ommitted, 'packages.backup.d' is used."
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
    mkdir $directory
fi

# Create a package list for restore
dpkg --get-selections | awk '!/deinstall|purge|hold/ {print $1}' > $directory"/"packages.list

# Get package states
apt-mark showauto > $directory"/"package-states-auto
apt-mark showmanual > $directory"/"package-states-manual

# Save package sources
find /etc/apt/sources.list* -type f -name '*.list' -exec bash -c 'echo -e "\n## $1 ";grep "^[[:space:]]*[^#[:space:]]" ${1}' _ {} \; > $directory"/"sources.list

# Get the trusted keys
cp /etc/apt/trusted.gpg $directory"/"trusted-keys.gpg
