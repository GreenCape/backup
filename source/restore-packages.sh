#!/bin/bash

# Default name of the package archive
archive="packages.tar.gz"
tar_options="--same-permissions --same-owner"

# Name of the temporary directory
directory="packages.tmp"$$".d"

usage () {
    echo ""
    echo "Usage: "$(basename $0)" [options]"
    echo ""
    echo "  -a, --archive=filename   The filename of the package dump."
    echo "                 If ommitted, '$archive' is expected."
    echo "  -h, --help     Show this messsage"
    echo "  -n, --no-system   Exclude system (/etc, /opt, /root, /usr, /var)"
    echo "  -v, --verbose  Show more output"
    echo ""
}

# Get option arguments
has_error="no"
include_system="yes"
apt_verbosity="-qq"

INPUT=$(getopt -n "$0" -o a:hnv --long "archive:,help,no-system,verbose" -n "GreenCape Package Restore" -- "$@")
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
            exit 0
            ;;
        -n|--no-system)
            include_system="no"
            break
            ;;
        -v|--verbose)
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

if ! [[ -e $archive ]]
then
    echo "Unable to locate package dump. '$archive' not found." >&2
    exit 1;
fi

# Extract archive
cd "$directory"
tar -xzf "$archive" $tar_options

# Sync the source list
rm /etc/apt/sources.list.d/restore.list
find /etc/apt/sources.list* -type f -name '*.list' -exec bash -c 'grep "^deb" ${1}' _ {} \; | sort > "$directory/known-sources.list"
comm -13 "$directory/known-sources.list" "$directory/sources.list" > /etc/apt/sources.list.d/restore.list

# Import the trusted keys
apt-key add "$directory/trusted-keys.gpg"
apt-get update

# Install packages
xargs -a "$directory/packages.list" apt-get $apt_verbosity install

# Restore package states
xargs -a "$directory/package-states-auto" apt-mark $apt_verbosity auto
xargs -a "$directory/package-states-manual" apt-mark $apt_verbosity manual

# Optionally include system settings
if [ "$include_system" == "yes" ] && [[ -e etc.tar ]]
then
    tar -xf files.tar $tar_options -C /
fi

# Cleanup
cd "$OLDPWD"
rm -rf "$directory"
