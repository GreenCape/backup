#!/bin/bash

# Default name of the package archive
archive="packages.tar.gz"

# Name of the temporary directory
directory="packages.tmp"$$".d"

usage () {
    echo ""
    echo "Usage: "$(basename $0)" [options]"
    echo ""
    echo "  -a, --archive=filename   The filename of the package dump."
    echo "                 If ommitted, '$archive' is expected."
    echo "  -h | --help    Show this messsage"
    echo ""
}

# Get option arguments
has_error="no"

INPUT=$(getopt -n "$0" -o a:h --long "archive:,help" -n "GreenCape Package Restore" -- "$@")
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

if ! [[ -e $archive ]]
then
    echo "Unable to locate package dump. '$archive' not found." >&2
    exit 1;
fi

# Extract archive
cd "$directory"
tar -xzf "$archive"

# Sync the source list
cp "$directory/sources.list" /etc/apt/sources.list.d/restore.list

# Import the trusted keys
apt-key add "$directory/trusted-keys.gpg"
apt-get update

# Install packages
xargs -a "$directory/packages.list" apt-get install

# Restore package states
xargs -a "$directory/package-states-auto" apt-mark auto
xargs -a "$directory/package-states-manual" apt-mark manual

# Cleanup
cd "$OLDPWD"
rm -rf "$directory"
