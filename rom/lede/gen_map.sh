#!/bin/sh

CFGS=${CFGS-"`cat feeds/ptpt52/rom/lede/cfg.list`"}

bins="`find bin/targets/ | grep -- '\(-ext4-sdcard\|-squashfs\|-factory\|-sysupgrade\|\.bin\)' | grep natcap | grep -v vmlinux | grep -v '\.dtb$' | while read line; do basename $line; done`"

sha256sums="`find bin/targets/ -type f -name sha256sums`"
sha256sums=`cat $sha256sums`

targets=$(cd feeds/ptpt52/rom/lede/ && cat $CFGS | grep TARGET_DEVICE_.*=y | sed 's/CONFIG_//;s/=y//' | sort)

echo -n >map.sha256sums
echo -n >map.list

echo sha256sums: map.sha256sums >>map.list

x86bin="`find bin/targets/ | grep -- -combined | while read line; do basename $line; done`"
test -n "$x86bin" && {
	echo x86_64 or x86:
	echo "$x86bin"
	echo
	for bin in $x86bin; do
		echo "$sha256sums" | grep "$bin" >>map.sha256sums
		echo "x86_64 or x86:$bin" >>map.list
	done
}

for t in $targets; do
	tt=`echo $t | sed 's/_DEVICE_/:/g'`
	name=`echo $tt | cut -d: -f3`
	echo $tt | cut -d: -f2 | sed 's/_/ /' | while read arch subarch; do
		test -n "$arch" || continue
		text=`cat target/linux/$arch/image/*.mk target/linux/$arch/image/Makefile 2>/dev/null | grep "define .*Device\/$name$" -A20 | while read line; do [ "x$line" = "xendef" ] && break; echo $line; done`
		dis=`echo "$text" | grep "DEVICE_TITLE.*:=" | head -n1 | sed 's/DEVICE_TITLE.*:=//'`
		test -n "$dis" || {
			dis=`echo "$text" | grep '$(call Device' | head -n1 | cut -d, -f2 | sed 's/)$//g'`
		}
		bin=`echo "$bins" | grep -i "\($name-e\|$name-s\|$name-f\|$name-u\|$name-i\)"`
		test -n "$bin" || {
			name=`echo $name | tr _ -`
			bin=`echo "$bins" | grep -i "\($name-s\|$name-f\|$name-u\)"`
			test -n "$bin" || {
				bin=$(echo "$bins" | grep -i "`echo $name | head -c5`" | grep $arch)
				test -n "$bin" || {
					bin=$(echo "$bins" | grep -i "`echo $name | head -c3`" | grep $arch)
				}
			}
		}
		echo "`echo $dis`:"
		for i in $bin; do
			echo $i;
			echo "$sha256sums" | grep "$i" >>map.sha256sums
		done
		echo
		echo "`echo $dis`:"$bin >>map.list
	done
done | while read line; do echo $line; done
