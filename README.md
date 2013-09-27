# GreenCape Backup

**GreenCape Backup** is a versatile backup and restore solution for Linux systems following the
Filesystem Hierarchy Standard.

## Features

**GreenCape Backup** is a single script solution, which

 -  makes full backup
 -  uses `apt` to handle the installed packages, package sources, and trusted keys internally.
 -  preserves access times, permissions, and owners.
 -  optionally excludes system files.
 -  optionally excludes caches and backup files.

## Requirements

There are no requirements but a current Linux system that follows the
[Filesystem Hierarchy Standard](http://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard).

## Installation

No installation required. Just copy the script `gc-bak.sh` to your home directory and make it
executable.

`$ chmod +x gc-bak.sh`

That's all it takes to get ready for a backup.

## Introduction

Everyone working with electronic media should be aware of data protection.
It happens all over the time that data are irretrievably lost due to hardware faults,
system errors or user errors (the most common type).
Through a regular backup the total loss of data can be prevented.
In particular, facing profound changes to the system, such as partitioning, a backup is a must.

### Terms

 -  **Full Backup**: Backup of the entire dataset.
 -  **Differential Backup**: Contains all the changes that have occurred since the last full backup.
 -  **Incremental Backup**: Contains all the changes that were made since the last backup
    (full backup or incremental backup).
 -  **Images**: Backup of complete partitions or disks
 -  **RAID**: RAID array of two or more hard drives in which all data is stored several times
    (redundant) and one is protected against failure of one or more individual drives.
    There are different RAID levels, of which only RAID 0 is inappropriate.

    **Warning: RAID is no substitute for a data backup!**

### Strategies

The following questions should be asked by everyone who is concerned with the security of his data:

 -  What data should I back up and where do I find it?
 -  How often should a backup be performed?
 -  Where should I store the backup?
 -  Where should I deposit the backup media?

## Backup with GreenCape Backup

**GreenCape Backup** is made to make backups easy. It is able to backup a complete system, so it
can be restored on a fresh install. Internally, it uses `apt` to handle the installed packages,
package sources, and trusted keys.

### Operation mode

The operation modes *backup* or *restore* are invoked using the `-b|--backup` or `-r|--restore`
switches respectively. `--backup` is the default operation mode.

### Packages

**GreenCape Backup** creates a list of all installed packages, their states, corresponding
sources and trusted keys. This information is used during a restore to re-install those packages.

### System files

As per default, **GreenCape Backup** includes all system files, i.e., the content of the
directories `/etc`, `/opt`, `/usr/local`, `/var/games`, `/var/lib`, `/var/local`, `/var/mail`,
`/var/opt`, and `/var/www`. The inclusion of the system files can be suppressed by using the
`-n|--no-system` option.

The system directories may contain cache data or local backups. The inclusion of these files
can be suppressed using the `-c|--clean` option.

## Examples

Backup packages and system files without cache data and local backup files:

`$ sudo ./gc-bak.sh --backup --clean`

Restore on a new install:

`$ sudo ./gc-bak.sh --restore`

## Contribution

## Versioning

For transparency and insight into our release cycle, and for striving to maintain backwards
compatibility, **GreenCape Backup** will be maintained under the Semantic Versioning guidelines
as much as possible.

Releases will be numbered with the follow format:

`<major>.<minor>.<patch>`

And constructed with the following guidelines:

* Breaking backwards compatibility bumps the major
* New additions without breaking backwards compatibility bumps the minor
* Bug fixes and misc changes bump the patch

For more information on SemVer, please visit http://semver.org/.


## Bug Tracker

Have a bug? Please create an issue here on GitHub!

https://github.com/GreenCape/backup/issues

<!--
## Twitter Account

Keep up to date on announcements and more by following **GreenCape** on Twitter,
<a href="http://twitter.com/GreenCape">@GreenCape</a>.


## Mailing List

Have a question? Ask on our mailing list!

greencape-backup@googlegroups.com

http://groups.google.com/group/greencape-backup
-->

## Authors

**Niels Braczek** [ [Twitter](http://twitter.com/hiPHPie) | [GitHub](http://github.com/nibra) ]


## License

Copyright &copy;2013 BSDS Braczek Software- und DatenSysteme. All rights reserved.

Licensed under the GNU General Public License version 2 or later: http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html