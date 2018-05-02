#!/data/data/com.termux/files/usr/bin/bash
folder=ubuntu-fs
if [ -d "$folder" ]; then
	first=1
	echo "skipping downloading"
fi
while [[ $env != 0 ]]; do
u_version="\nPlease select the Ubuntu version:

    1. Ubuntu 18.04 Bionic
    2. Ubuntu 17.10 Artful
    3. Ubuntu 16.04 Xenial
    
"
echo -e "$u_version"
read env;
case $env in
  1) echo -e "\nInstalling Ubuntu 18.04 Bionic"
      ubuntu_version="bionic"
      break;;
  2) echo -e "\nInstalling Ubuntu 17.10 Artful"
      ubuntu_version="artful"
      break;;
  3) echo -e "\nInstalling Ubuntu 16.04 Xenial"
      ubuntu_version="xenial"
      break;;
  *) echo -e "\nPlease enter the correct option";;
esac
done
tarball="ubuntu.tar.gz"
if [ "$first" != 1 ];then
	if [ ! -f $tarball ]; then
		echo "downloading ubuntu-image"
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
			echo "unknown architecture"; exit 1 ;;
		esac
		wget "https://partner-images.canonical.com/core/${ubuntu_version}/current/ubuntu-${ubuntu_version}-core-cloudimg-${archurl}-root.tar.gz" -O $tarball
	fi
	cur=`pwd`
	mkdir -p "$folder"
	cd "$folder"
	echo "decompressing ubuntu image"
	proot --link2symlink tar -xf ${cur}/${tarball} --exclude='dev'||:
	echo "fixing nameserver, otherwise it can't connect to the internet"
	echo "nameserver 1.1.1.1" > etc/resolv.conf
	cd "$cur"
fi
mkdir -p binds
bin=$PREFIX/bin/ubuntu
echo "writing launch script"
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
command+=" LANG=\$LANG"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM
chmod 777 $bin
echo "fixing shebang of $bin"
termux-fix-shebang $bin
echo "making $bin executable"
chmod +x $bin
echo "You can now launch Ubuntu with the command ubuntu"
