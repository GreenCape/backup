#!/bin/bash

# Default name of the package archive
archive="packages.tar.gz"
tar_options="--atime-preserve=system --preserve-permissions --same-owner"

# Name of the temporary directory
directory="packages.tmp"$$".d"

usage () {
    echo ""
    echo "Usage: "$(basename $0)" [options]"
    echo ""
    echo "  -a, --archive=filename   The filename for the package dump."
    echo "                 If ommitted, '$archive' is used."
    echo "  -c, --clean    Exclude caches and backup files"
    echo "  -h, --help     Show this messsage"
    echo "  -n, --no-settings   Don't backup system settings (/etc)"
    echo "  -v, --verbose  Show more output"
    echo ""
}

# Get option arguments
has_error="no"
clean="no"
include_etc="yes"
verbose="no"
apt_verbosity="-qq"

INPUT=$(getopt -n "$0" -o a:chnv --long "archive:,clean,help,no-settings,verbose" -n "GreenCape Package Backup" -- "$@")
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
        -c|--clean)
            clean="yes"
            tar_options="$tar_options --exclude-caches --exclude-backups"
            break
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -n|--no-settings)
            include_etc="no"
            break
            ;;
        -v|--verbose)
            verbose="yes"
            apt_verbosity="-q"
            tar_options="$tar_options --verbose"
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
if [ "$verbose" == "yes" ]; then echo -e "\nDumping packages list"; fi
dpkg --get-selections | awk '!/deinstall|purge|hold/ {print $1}' > "$directory/packages.list"

# Get package states
if [ "$verbose" == "yes" ]; then echo -e "\nDumping package states"; fi
apt-mark showauto > "$directory/package-states-auto"
apt-mark showmanual > "$directory/package-states-manual"

# Save package sources
if [ "$verbose" == "yes" ]; then echo -e "\nDumping package sources"; fi
find /etc/apt/sources.list* -type f -name '*.list' -exec bash -c 'grep "^deb" ${1}' _ {} \; | sort > "$directory/sources.list"

# Get the trusted keys
if [ "$verbose" == "yes" ]; then echo -e "\nDumping trusted keys"; fi
cp /etc/apt/trusted.gpg "$directory/trusted-keys.gpg"

# Optionally include system settings
if [ "$include_etc" == "yes" ]
then
    if [ "$verbose" == "yes" ]; then echo -e "\nDumping system settings"; fi
    tar -cf "$directory/etc.tar" $tar_options -C / etc
fi

# Create archive
cd "$directory"
if [ "$verbose" == "yes" ]; then echo -e "\nPacking archive '$archive'"; fi
tar -czf "$archive" $tar_options *
cd "$OLDPWD"
if [ "$verbose" == "yes" ]; then echo -e "\nRemoving temporary files"; fi
rm -rf "$directory"

if [ "$verbose" == "yes" ]; then echo -e "\nDone."; fi
