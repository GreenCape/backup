#!/bin/sh

# @see http://wiki.ubuntuusers.de/Paketverwaltung/Tipps#Paketliste-zur-Wiederherstellung-erzeugen

# Checking for user - this operation needs root permissions
if [ "$(whoami)" != 'root' ]
then
    echo "You have no permission to run $0 as non-root user. Use sudo!" >&2
    exit 1;
fi

# Sync the source list
cp sources.list /etc/apt/sources.list.d/restore.list

# Import the trusted keys
apt-key add trusted-keys.gpg
apt-get update

# Install packages
xargs -a "packages.list" apt-get install

# Restore package states
xargs -a "package-states-auto" apt-mark auto
xargs -a "package-states-manual" apt-mark manual
