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
    echo "  -n, --no-settings   Don't restore system settings (/etc)"
    echo "  -v, --verbose  Show more output"
    echo ""
}

# Get option arguments
has_error="no"
include_etc="yes"
verbosity="-qq"

INPUT=$(getopt -n "$0" -o a:hv --long "archive:,help,verbose" -n "GreenCape Package Restore" -- "$@")
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
        -n|--no-settings)
            include_etc="no"
            break
            ;;
        -v|--verbose)
            verbosity="-q"
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
xargs -a "$directory/packages.list" apt-get $verbosity install

# Restore package states
xargs -a "$directory/package-states-auto" apt-mark $verbosity auto
xargs -a "$directory/package-states-manual" apt-mark $verbosity manual

# Optionally include system settings
if [ "$include_etc" == "yes" ] && [[ -e etc.tar ]]
then
    tar -xf etc.tar -C /
fi

# Cleanup
cd "$OLDPWD"
rm -rf "$directory"
