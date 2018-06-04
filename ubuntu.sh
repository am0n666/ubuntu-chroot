#!/data/data/com.termux/files/usr/bin/bash
me="\e[38;5;196m"
hi="\e[38;5;82m"
no="\e[0m"
folder=ubuntu-fs
cur=$(pwd)
if [ -d "$folder" ]; then
	first=1
	echo "skipping downloading"
fi
while [[ $env != 0 ]]; do
echo -e "\nPlease select the Ubuntu version:

    1. Ubuntu 18.10 Bionic
    2. Ubuntu 17.10 Artful
    3. Ubuntu 16.04 Xenial
    
"
read env;
case $env in
  1) echo -e "\nDowloading Ubuntu 18.10 Bionic\n"
      ubuntu_version="bionic"
      break;;
  2) echo -e "\nDowloading Ubuntu 17.10 Artful\n"
      ubuntu_version="artful"
      break;;
  3) echo -e "\nDowloading Ubuntu 16.04 Xenial\n"
      ubuntu_version="xenial"
      break;;
  *) echo -e "\nPlease enter the correct option\n";;
esac
done
tarball="ubuntu.tar.gz"
case `dpkg --print-architecture` in
				aarch64)
						archurl="arm64" ;;
				arm)
						archurl="armhf" ;;
                amd64)
                        archurl="amd64" ;;
				i*86)
                        archurl="i386" ;;
                *)
                        echo "unknown architecture"; exit 1 ;;                          esac
shasum="sha256_${ubuntu_version}_${archurl}"
if [ "$first" != 1 ];then
	if [ ! -f $tarball ]; then
		wget "https://partner-images.canonical.com/core/${ubuntu_version}/current/ubuntu-${ubuntu_version}-core-cloudimg-${archurl}-root.tar.gz"
		echo -e "\ndownloading sha256sum\n"
		wget "https://partner-images.canonical.com/core/${ubuntu_version}/current/SHA256SUMS" -O $shasum
	fi
	echo -e "\nchecking integrity...\n"
	cat $shasum | grep "$archurl" >> sha256
	rm $shasum
	check="$(sha256sum -c sha256 | cut -d" " -f2)"
	if [ "$check" != "OK" ]; then
	echo -e "\nintegrity check... ${me}${check}!${no} downloaded image file was corrupted or half downloaded!rerun the script again."
	yes | rm -R !(ubuntu.sh)
	exit
	else
	echo -e "\nintegrity check... ${hi}${check}$no\n"
	mv *.tar.gz $tarball
	cur=`pwd`
	mkdir -p "$folder"
	cd "$folder"
	echo -e "decompressing ubuntu image\n"
	proot --link2symlink tar -xf ${cur}/${tarball} --exclude='dev'||:
	echo "fixing nameserver, otherwise it can't connect to the internet"
	echo "nameserver 8.8.8.8" > etc/resolv.conf
	rm $tarball
	rm sha256
	cd "$cur"
	fi
fi
mkdir -p binds
bin=start.sh
echo -e "writing launch script\n"
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $cur/ubuntu-fs"
if [ -n "\$(ls -A $cur/binds)" ]; then
    for f in $cur/binds/* ;do
      . \$f
    done
fi
command+=" -b /system"
command+=" -b /dev"
command+=" -b /sys"
command+=" -b /proc"
## uncomment the following line to have access to the home directory of termux
command+=" -b /data/data/com.termux/files/home"
command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" LC_ALL=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM
ln -s $cur/$bin $PREFIX/bin/ubuntu
chmod 777 $bin
echo -e "fixing shebang of $bin\n"
termux-fix-shebang $bin
echo -e "making $bin executable\n"
chmod +x $bin
echo "You can now launch Ubuntu with the command <ubuntu>"
