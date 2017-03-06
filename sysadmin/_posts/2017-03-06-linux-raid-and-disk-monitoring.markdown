---
title: Linux RAID and disk monitoring
layout: post
category: sysadmin
date: 2017-03-06
---

I recently found my home file server in a sorry state. My backup hard drive had
died as well as one of the two disks in the main RAID 1 (mirrored) array where
all my files and music are being served from. It was time to fix things up and
ensure I'd be alerted when things failed in the future.

Below are some notes on the steps I took to create a new RAID 1 array (I had
some funky partitioning on the old one and didn't want to just replace the
failed disk), safely copy my data to the new array, and setup `smartmontools` to
monitor the disks and alert me when a disk started to fail.


## smartmontools

The first thing I did was install the `smartmontools` package to test the
existing drives. I knew `/dev/sdc` was having problems so I used the following
commands to get more information.

First, install the package: `sudo apt-get install smartmontools`.

`smartctl -i /dev/sdc` gives high level overview of drive. The output should
show `SMART support is: Enabled` in order for `smartmontools` to monitor the
drive. Otherwise SMART can be enabled via `sudo smartctl -s on /dev/sdc`.

`smartctl -c /dev/sdc` gives test time estimates. `smartctl -t long /dev/sdc`
runs long test. A `short` test can also be run. `smartctl -l selftest /dev/sdc`
will show the test result stats.

More detail can be seen about the disk with `smartctl -a /dev/sdc`. This will
show recent errors, test results, and other stats.

I found that `/dev/sdc` in my server was failing with read errors during tests.
The other disk in the array was just as old as the failing disk so I decided to
replace that as well as a precaution.

I also wanted to configure smartmontools as a daemon to run tests and email
`root` when there are issues. To enable that:

  * Uncomment `start_smartd=yes` from `/etc/default/smartmontools`
  * Ensure line exists in `/etc/smartd.conf`
```
DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner
```
  * `smartd` will now monitor the disks after a reboot, but it can be started
  immediately as well with `sudo service smartmontools start`.


## Recovery Plan

  1. Capture a fresh backup
  2. Get a checksum of everything on the partition
```
find --type f --exec md5sum "{}" + > data-old.chk
```
  This took quite a while to run over 30k files.
  3. Use `smartctl -i /dev/sdc` to get the SN of the bad disk
  4. Shutdown and pull the bad disk. Replace with a fresh disk and a second
     fresh disk in the empty bay
  5. Create new partitions on the 2 new disks and create a new RAID 1 array
     that uses the "whole" disk. I actually lefte 100MB at the end of the disk
     after reading about some issues with manufacturer size variability when
     replacing disks.
  7. mount old data on `/mnt/data-old` and new array on `/mnt/data-new`.
     `rsync -avP /mnt/data-old/* /mnt/data-new/`
  8. `cd /mnt/data-new; md5sum -c data-old.chk > data-old-check.out &` to
     verify all data is there and matches the old partition. This wasn't really
     necessary when using `rsync`, but I was paranoid.
  9. Remount `/mnt/data-new` in it's normal spot.
  10. Destroy old RAID devices and remove remaining old disk



## Creating the new RAID device with mdadm

Initialize the disk by running `sudo parted -a optimal /dev/sdc`. In the
`parted` prompt I created a new partition table with `mklabel gpt`, then I made a
new partition taking up the entire disk but leaving 100MB at the end in case of
future replacement disks not being the exact same size, `mkpart primary 1MiB
-100MiB`. This procedure was then repeated on the other new disk and they were
ready to be used for a new RAID 1 array.

The new array was created with:
```
sudo mdadm --create --verbose /dev/md0 --level=mirror --raid-devices=2 /dev/sdc1 /dev/sdd1
```

`mdadm` will then have to copy over all the garbage from one disk to the other,
even though the disks are "empty", to ensure they are mirrors of each other.
This is monitored with `sudo cat /proc/mdstat` and the `watch` command if you're
into that type of thing. This took many many hours with my 2TB disks.

It's also a good idea to put the output of `sudo mdadm --detail --scan` in
`/etc/mdadm/mdadm.conf`.

Once I had all the data transferred and verified on the new array it was time to
remove the old RAID device:
```
# Be sure to unmount the device first
sudo mdadm --stop /dev/md127
sudo mdadm --remove /dev/md127
```

The old drive was then removed and physically destroyed.
