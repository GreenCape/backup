#!/bin/sh

# @see http://wiki.ubuntuusers.de/Paketverwaltung/Tipps#Paketliste-zur-Wiederherstellung-erzeugen

# Checking for user - this operation needs root permissions
if [ "$(whoami)" != 'root' ]
then
    echo "You have no permission to run $0 as non-root user. Use sudo!" >&2
    exit 1;
fi

# Create a package list for restore
dpkg --get-selections | awk '!/deinstall|purge|hold/ {print $1}' > packages.list

# Get package states
apt-mark showauto > package-states-auto
apt-mark showmanual > package-states-manual

# Save package sources
find /etc/apt/sources.list* -type f -name '*.list' -exec bash -c 'echo -e "\n## $1 ";grep "^[[:space:]]*[^#[:space:]]" ${1}' _ {} \; > sources.list

# Get the trusted keys
cp /etc/apt/trusted.gpg trusted-keys.gpg
