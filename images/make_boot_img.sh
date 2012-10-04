#!/bin/sh

if [ "`arch`" = "x86_64" ]; then
    wordsize=64
else
    wordsize=32
fi

initrd() {
    if [ -n "$USE_LOCAL_STAGE1" ]; then
	stage1_root=../mdk-stage1
    else
	stage1_root=/usr/$lib/drakx-installer/binaries
    fi


    for dir in /dev /etc/sysconfig/network-scripts /firmware /lib /media/cdrom \
	/media/floppy /mnt /proc /run /sbin /sys /tmp /var/log /var/run \
	/var/tmp /tmp/newroot /tmp/stage2; do
	mkdir -p "$tmp_initrd$dir"
    done
    ln -s ../modules "$tmp_initrd/lib/modules"
    ln -s ../firmware "$tmp_initrd/lib/firmware"
    ln -s /proc/mounts "$tmp_initrd/etc/mtab"
    # XXX: drop
    ln -s ../tmp "$tmp_initrd/var/run/"

    install /usr/share/terminfo/l/linux -D "$tmp_initrd/usr/share/terminfo/l/linux"
    install -d "$tmp_initrd/usr/share/ldetect-lst"

    for table in pcitable usbtable; do
	zcat /usr/share/ldetect-lst/$table.gz > "$tmp_initrd/usr/share/ldetect-lst/$table"
    done
    install /usr/share/pci.ids -D "$tmp_initrd/usr/share/pci.ids"

    for alias in /usr/share/ldetect-lst/{dkms-modules,fallback-modules}.alias /lib/module-init-tools/ldetect-lst-modules.alias; do
	file="`basename $alias`"
	install $alias -D "$tmp_initrd/usr/share/ldetect-lst/$file"
    done

    for firm in all.kernels$I/$img/firmware/*; do
	file="`basename $firm`"
	cp -a "$firm" "$tmp_initrd/firmware/$file"
    done

    cat > "$tmp_initrd/etc/issue" <<EOF
    `linux_logo -l`

    [1;37;40mRescue Disk[0m

    $ENV{DISTRIB_DESCR}

    Use [1;33;40mloadkeys[0m to change your keyboard layout (eg: loadkeys fr)
    Use [1;33;40mmodprobe[0m to load modules (eg: modprobe snd-card-fm801)
    Use [1;33;40mdrvinst[0m to install drivers according to detected devices
    Use [1;33;40mblkid[0m to list your partitions with types
    Use [1;33;40mstartssh[0m to start an ssh daemon
    Use [1;33;40mrescue-gui[0m to go back to the rescue menu

EOF

	../tools/install-xml-file-list list.xml "$tmp_initrd"

	cp -r tree/* "$tmp_initrd"

	if false; then
	    install -m644 tree/etc/mdev.conf		-D $tmp_initrd/etc/mdev.conf
	    install -m755 tree/lib/mdev/dvbdev		-D $tmp_initrd/lib/mdev/dvbdev
	    install -m755 tree/lib/mdev/ide_links	-D $tmp_initrd/lib/mdev/ide_links
	    install -m755 tree/lib/mdev/usbdev		-D $tmp_initrd/lib/mdev/usbdev
	    install -m755 tree/lib/mdev/usbdisk_link	-D $tmp_initrd/lib/mdev/usbdisk_link
	fi

	for bin in `$tmp_initrd/usr/bin/busybox --list-full`; do
	    dir="`dirname \"$tmp_initrd/$bin\"`"
	    if [ ! -d "$dir" ]; then
		mkdir -p $dir
	    fi
	    ln -v "$tmp_initrd/usr/bin/busybox" "$tmp_initrd/$bin";
	done
	install -m755 "$stage1_root/stage1" -D "$tmp_initrd/sbin/stage1"

	for symlink in /bin/lspcidrake /bin/rescue-gui /sbin/drvinst \
	    /sbin/probe-modules /usr/bin/serial_probe /hotplug; do
	ln -v "$tmp_initrd/sbin/stage1" "$tmp_initrd$symlink"
    done

    for symlink in /usr/bin/dropbear /usr/bin/ssh /usr/bin/scp; do
	ln -v "$tmp_initrd/usr/bin/dropbearmulti" "$tmp_initrd$symlink"
    done

    ln -v "$tmp_initrd/sbin/init" "$tmp_initrd/init"

    LANGUAGE=C
    sed -e 's/^#LANGUAGE.*/export LANGUAGE=$LANGUAGE\nexport LC_ALL=$LANGUAGE\n/g' -i "$tmp_initrd/etc/init.d/rc.stage2"

    # XXX: prevent this from being added to begin with
    rm -rf "$tmp_initrd/usr/share/locale/"

    for f in `find "$tmp_initrd"`; do
	if [ -n "`file \"$f\"|grep 'not stripped'`" ]; then
	    strip "$f"
	fi
    done

    # ka deploy need some files in all.rdz 

    # install /usr/bin/ka-d-client -D "$tmp_initrd/ka/ka-d-client"

    #if [ -n "$DEBUG_INSTALL" ]; then
    #    for f in `rpm -ql valgrind`; do
    #	test -d "$f" || install "$f" -D "$tmp_initrd$f"

    #    foreach my $f (("libc.so.6", "libpthread.so.0", "ld-linux-" . ($wordsize eq "64" ? "x86-64" : "") . ".so.2")) {
    #			_ "install -m755 /$lib/$f -D $tmp_initrd/$lib/$f";
    #		}
    #	}
    #    }
    if [ -z "$COMPRESS" ]; then
	COMPRESS="xz --x86 --lzma2 -v9e --check=crc32"
    fi

    mkdir -p "`dirname \"$img\"`"
    (cd "$tmp_initrd"; find . | cpio -o -H newc --quiet) | $COMPRESS > "$img"
}

modules() {
    out=$1
    I=$2
    mkdir -p "$tmp_initrd/modules"
    modz="all.kernels/$I";
    mkdir -p "$tmp_initrd/lib/modules/$I"
    tar xC "$tmp_initrd/lib/modules/$I" -f "$modz/all_modules.tar"
    for n in order builtin; do
	    cp -f $modz/modules.$n "$tmp_initrd/lib/modules/$I"
    done
    sed -e 's#.*/##g' -i "$tmp_initrd/lib/modules/$I/modules.order"
    /sbin/depmod -b "$tmp_initrd" $I
    # depmod keeps only available modules in modules.alias, but we want them all
    cp -f $modz/modules.alias "$tmp_initrd/lib/modules/$I";

    if [ -z "$COMPRESS" ]; then
	    COMPRESS="xz --lzma2 -v9e --check=crc32"
    fi

    mkdir -p "`dirname \"$out\"`"
    (cd "$tmp_initrd"; find . | cpio -o -H newc --quiet) | $COMPRESS > "$out"
    rm -rf "$tmp_initrd"
}

grub() {
    dir=$1
    install -m644 grub_data/grub.cfg -D "$dir/boot/grub/grub.cfg"
    install -m644 grub_data/themes/moondrake/theme.txt -D "$dir/boot/grub/themes/moondrake/theme.txt"
    install -m644 grub_data/themes/moondrake/star_w.png -D "$dir/boot/grub/themes/moondrake/star_w.png"
    install -m644 /usr/share/gfxboot/themes/Mandriva/install/back.jpg -D "$dir/boot/grub/themes/moondrake/background.jpg"
    mkdir -p "$dir/boot/grub/fonts/"
    grub2-mkfont -o "$dir/boot/grub/fonts/dejavu.pf2" /usr/share/fonts/TTF/dejavu/DejaVuSans-Bold.ttf;


    if [ ! -s all.kernels/.list ]; then
	    echo grub: no kernel >&2
    fi

    N=0
    for I in `cat all.kernels/.list`; do
	path="$dir/boot/alt$N"
	N=$((N+1))
	mkdir -p "$path"
	install -m644 all.kernels/$I/vmlinuz -D $path/$wordsize/vmlinuz
	modules images/modules.rdz-$I $I
	mv "images/modules.rdz-$_" "$path/$wordsize/modules.rdz"
    done

    install -m644 /boot/memtest* -D $dir/boot/memtest
}

img="$1"
filename="`basename \"$img\"`"
lib=`rpm -E %_lib`
tmp_initrd="$PWD/tmp_initrd"
rm -rf "$tmp_initrd"


if [ "$filename" = "all.rdz" ]; then
    initrd
elif [ "$filename" = "modules.rdz" ]; then
    modules $1
elif [ "$filename" = "grub" ]; then
    grub $1
fi