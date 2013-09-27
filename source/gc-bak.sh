#!/bin/bash

app_name="GreenCape Backup"
app_version="0.1.0"
archive="packages.tar.gz"
tar_options="--atime-preserve=system --preserve-permissions --same-owner"
sys_files="etc opt usr/local var/games var/lib var/local var/mail var/opt var/www"

# Name of the temporary directory
directory="packages.tmp"$$".d"

usage () {
    echo ""
    echo "Usage: "$(basename $0)" [options]"
    echo ""
    echo "  -b, --backup   Perform backup (default)"
    echo "  -r, --restore  Restore backup"
    echo ""
    echo "  -a, --archive=filename   The filename of the dump."
    echo "                 If ommitted, '$archive' is used."
    echo "  -c, --clean    Exclude caches and backup files (--backup only)"
    echo "  -h, --help     Show this messsage"
    echo "  -n, --no-system   Exclude system (/etc, /opt, /root, /usr, /var)"
    echo "  -v, --verbose  Show more output"
    echo ""
}

# Get option arguments
has_error="no"
clean="no"
include_system="yes"
verbose="no"
apt_verbosity="-qq"
operation="backup"

INPUT=$(getopt --n "$(basename $0)" -o a:bchnrv --long "archive:,backup,clean,help,no-system,restore,verbose" -- "$@")

if [ $? -ne 0 ]
then
    exit 1
fi
eval set -- "$INPUT"

while true
do
    case "$1" in
        -b|--backup)
            operation="backup"
            shift
            ;;
        -r|--restore)
            operation="restore"
            shift
            ;;
        -a|--archive)
            archive=$2
            shift 2
            ;;
        -c|--clean)
            clean="yes"
            tar_options="$tar_options --exclude-caches --exclude-backups"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -n|--no-system)
            include_system="no"
            shift
            ;;
        -v|--verbose)
            verbose="yes"
            apt_verbosity=""
            #tar_options="$tar_options --verbose"
            shift
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

cd "$directory"

echo -e "$app_name $app_version\n"

if [ "$operation" == "backup" ]
then
    mode="Backup"
    if [ "$include_system" == "yes" ]
    then
        mode="$mode\n- including system files"
    fi
    if [ "$clean" == "yes" ]
    then
        mode="$mode\n- excluding caches and backups"
    fi
    echo -e "$mode\n"

    # Create a package list for restore
    if [ "$verbose" == "yes" ]; then echo "Dumping packages list"; fi
    dpkg --get-selections | awk '!/deinstall|purge|hold/ {print $1}' > packages.list

    # Get package states
    if [ "$verbose" == "yes" ]; then echo "Dumping package states"; fi
    apt-mark showauto > package-states-auto
    apt-mark showmanual > package-states-manual

    # Save package sources
    if [ "$verbose" == "yes" ]; then echo "Dumping package sources"; fi
    find /etc/apt/sources.list* -type f -name '*.list' -exec bash -c 'grep "^deb" ${1}' _ {} \; | sort > sources.list

    # Get the trusted keys
    cp /etc/apt/trusted.gpg trusted-keys.gpg

    # Optionally include system settings
    if [ "$include_system" == "yes" ]
    then
        if [ "$verbose" == "yes" ]; then echo "Dumping system files"; fi
        tar -cf files.tar $tar_options -C / $sys_files
    fi

    # Create archive
    if [ "$verbose" == "yes" ]; then echo "Creating archive"; fi
    tar -czf "$archive" $tar_options *
elif [ "$operation" == "restore" ]
then
    if ! [[ -e $archive ]]
    then
        echo "Unable to locate package dump. '$archive' not found." >&2
        exit 1;
    fi

    mode="Restore"
    if [ "$include_system" == "yes" ]
    then
        mode="$mode\n- including system files"
    fi
    if [ "$clean" == "yes" ]
    then
        mode="$mode\n- excluding caches and backups"
    fi
    echo -e "$mode\n"

    # Extract archive
    if [ "$verbose" == "yes" ]; then echo "Extracting archive"; fi
    tar -xzf "$archive" $tar_options

    # Sync the source list
    if [ "$verbose" == "yes" ]; then echo "Sync'ing sources list"; fi
    rm /etc/apt/sources.list.d/restore.list
    find /etc/apt/sources.list* -type f -name '*.list' -exec bash -c 'grep "^deb" ${1}' _ {} \; | sort > "$directory/known-sources.list"
    comm -13 "$directory/known-sources.list" "$directory/sources.list" > /etc/apt/sources.list.d/restore.list

    # Import the trusted keys
    apt-key add "$directory/trusted-keys.gpg"
    apt-get update

    # Install packages
    if [ "$verbose" == "yes" ]; then echo "Installing packages"; fi
    xargs -a "$directory/packages.list" apt-get $apt_verbosity install

    # Restore package states
    if [ "$verbose" == "yes" ]; then echo "Restoring package states"; fi
    xargs -a "$directory/package-states-auto" apt-mark -qq auto
    xargs -a "$directory/package-states-manual" apt-mark -qq manual

    # Optionally include system settings
    if [ "$include_system" == "yes" ] && [[ -e files.tar ]]
    then
        if [ "$verbose" == "yes" ]; then echo "Restoring system files"; fi
        tar -xf files.tar $tar_options -C /
    fi
fi

###

# Cleanup
cd "$OLDPWD"
rm -rf "$directory"

if [ "$verbose" == "yes" ]; then echo -e "\nDone."; fi
