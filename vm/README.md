Testing your Backup
===================

    You should always have in mind, that you want to restore your data in case of data loss,
    and not just want to have a backup, that cannot be restored.

Virtual Machine
---------------

Since the backup might be restored on bare metal with a virgin operating system, it is best
to test the backup on a virtual machine.

 1. Create or download a virtual machine corresponding to your setup, for example, Ubuntu 12.04.
    A very comprehensive tutorial for the installation and setup of a virtual box is found at
    `http://wiki.ubuntuusers.de/VirtualBox/Installation` [de_DE]

 2. Update the virtual machine to the most recent versions of the installed software (as you do
    with your production machine).

        # apt-get update
        # apt-get upgrade

    This may take a while, especially, if you're using an LTS version, which initial release may
    have happened some years ago.

 3. Store the current state as a savepoint.

Testing the Package Backup
--------------------------

Once your virtual machine is set up, you can test your backup.

 1. On your production machine, copy the backup on a USB stick, together with the restore script.

 2. On the virtual machine, copy the files to an empty directory, e.g., `~/restore`.

 3. Run the restore script as root:

        # cd ~/restore
        # ./restore-packages.sh > restore.log

 4. Check the log for any problems.

