#!/bin/bash

# Default name of the package archive
archive="packages.tar.gz"

# Name of the temporary directory
directory="packages.tmp"$$".d"

usage () {
    echo ""
    echo "Usage: "$(basename $0)" [options]"
    echo ""
    echo "  -a, --archive=filename   The filename for the package dump."
    echo "                 If ommitted, '$archive' is used."
    echo "  -h, --help     Show this messsage"
    echo ""
}

# Get option arguments
has_error="no"

INPUT=$(getopt -n "$0" -o a:h --long "archive:,help" -n "GreenCape Package Backup" -- "$@")
if [ $? -ne 0 ]
then
    exit 1
fi
eval set -- "$INPUT"

while true
do
    case "$1" in
        -a|--archive)
            archive=$2
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
    directory="$PWD/$directory"
fi
if ! [[ -e "$directory" ]]
then
    mkdir "$directory"
fi

if [ "${archive:0:1}" != "/" ]
then
    archive="$PWD/$archive"
fi

# Create a package list for restore
dpkg --get-selections | awk '!/deinstall|purge|hold/ {print $1}' > "$directory/packages.list"

# Get package states
apt-mark showauto > "$directory/package-states-auto"
apt-mark showmanual > "$directory/package-states-manual"

# Save package sources
find /etc/apt/sources.list* -type f -name '*.list' -exec bash -c 'grep "^deb" ${1}' _ {} \; | sort > "$directory/sources.list"

# Get the trusted keys
cp /etc/apt/trusted.gpg "$directory/trusted-keys.gpg"

# Create archive
cd "$directory"
tar -czf "$archive" *
cd "$OLDPWD"
rm -rf "$directory"