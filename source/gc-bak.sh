#!/bin/bash

app_name="GreenCape Backup"
app_version="0.2.0"
archive="backup.$(date +'%F-%H-%M-%S').tar.gz"
tar_options="--atime-preserve=system --preserve-permissions --same-owner"
sys_files="etc opt root usr/local usr/share var/games var/lib var/local var/mail var/opt var/www"

# Name of the temporary directory
directory="backup."$$".tmp.d"

usage () {
    echo ""
    echo "Usage: "$(basename $0)" [-b|-r] [options]"
    echo ""
    echo "Operation mode"
    echo "  -b, --backup"
    echo "                 Perform backup (default)"
    echo "  -r, --restore"
    echo "                 Restore backup"
    echo ""
    echo "Options"
    echo "  -a, --archive=filename"
    echo "                 The filename of the dump."
    echo "                 If ommitted, 'backup.YYYY-MM-DD-hh-mm-ss.tar.gz' is used."
    echo "  -c, --clean"
    echo "                 Exclude caches and backup files"
    echo "  -n, --no-system"
    echo "                 Exclude system files (/etc, /opt, /root, /usr, /var)"
    echo ""
    echo "  -u, --user=username"
    echo "                 Include username's home directory"
    echo "      --users"
    echo "                 Include all users' home directory"
    echo ""
    echo "  -h, --help"
    echo "                 Show this messsage"
    echo "  -v, --verbose"
    echo "                 Show more output"
    echo ""
}

# Get option arguments
has_error="no"
clean="no"
include_system="yes"
verbose="no"
apt_verbosity="-qq"
operation="backup"
users=""

INPUT=$(getopt --n "$(basename $0)" -o a:bchnru:v --long "archive:,backup,clean,help,no-system,restore,user:,users,verbose" -- "$@")

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
        --users)
            users="$(ls --hide="lost+found" /home)"
            shift
            ;;
        -u|--user)
            users="$users $2"
            shift 2
            ;;
        -v|--verbose)
            verbose="yes"
            apt_verbosity=""
            tar_options="$tar_options --verbose"
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

#echo -e "[operation: $operation; directory: $directory; archive: $archive]\n[clean: $clean; system: $include_system; verbose: $verbose]\n[users: $users]"
#exit 0

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

    exclude="--exclude='$directory/*'"
    if [ "$clean" == "yes" ]
    then
        exclude="$exclude --exclude='.thumbnails' --exclude='.cache' --exclude='.Trash' --exclude='temp'"
    fi

    for user in $users
    do
        if [ "$verbose" == "yes" ]; then echo "Dumping user data for $user"; fi
        tar_exclude=$exclude
        if [[ -e /home/$user/.gc-bak-exclude ]]
        then
            cat "/home/$user/.gc-bak-exclude"
            tar_exclude="$tar_exclude --exclude-from=/home/$user/.gc-bak-exclude"
        fi
        tar -cf $user.tar $tar_options $tar_exclude -C / home/$user
    done

    # Create archive
    if [ "$verbose" == "yes" ]; then echo "Creating archive"; fi
    tar -czf "$archive" $tar_options *
elif [ "$operation" == "restore" ]
then
    if ! [[ -e $archive ]]
    then
        #todo: try to find the latest backup
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
    rm /etc/apt/sources.list.d/gc-bak-gc-bak-restore.list
    find /etc/apt/sources.list* -type f -name '*.list' -exec bash -c 'grep "^deb" ${1}' _ {} \; | sort > "$directory/known-sources.list"
    comm -13 "$directory/known-sources.list" "$directory/sources.list" > /etc/apt/sources.list.d/gc-bak-restore.list

    # Import the trusted keys
    apt-key add "$directory/trusted-keys.gpg"
    apt-get update

    # Install packages
    if [ "$verbose" == "yes" ]; then echo "Installing packages"; fi
    xargs -a "$directory/packages.list" apt-get $apt_verbosity install
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
