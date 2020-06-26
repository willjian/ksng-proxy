#!/bin/bash

#download source
source_pkg="/usr/src/source_dl"
if [ ! -d "$source_pkg" ]; then
	mkdir $source_pkg
fi
imagick_src="${source_pkg}/ImageMagick-devel-pkgs"

download_src() {
	cd $source_pkg
	wget 150.95.112.141/IMAGICK-pkgs.tar.gz -qO IMAGICK-pkgs.tar.gz
	tar -xzf IMAGICK-pkgs.tar.gz
	rm -f IMAGICK-pkgs.tar.gz
}

install_imagick_devel_pkg() {
	cd $imagick_src
	rpm -ivh ghostscript-devel-9.07-28.el7_4.2.x86_64.rpm
	rpm -ivh jasper-devel-1.900.1-31.el7.x86_64.rpm
	rpm -ivh libXext-devel-1.3.3-3.el7.x86_64.rpm
	rpm -ivh libICE-devel-1.0.9-9.el7.x86_64.rpm
	rpm -ivh libSM-devel-1.2.2-2.el7.x86_64.rpm
	rpm -ivh libXt-devel-1.1.5-3.el7.x86_64.rpm
	rpm -ivh libtiff-devel-4.0.3-27.el7_3.x86_64.rpm
	rpm -ivh ImageMagick-devel-6.7.8.9-15.el7_2.x86_64.rpm
}

install_imagick_ext() {
	local php_ver=$1
	cp /etc/${php_ver}.d/php.ini /etc/${php_ver}.d/php.ini.bak
	sed -i -e 's/ popen,//' -e 's/ php_uname,//' /etc/${php_ver}.d/php.ini

	printf "\n" | /usr/local/${php_ver}/bin/pecl install imagick
	cp /etc/php7.d/extensions/50-imagick.ini /etc/${php_ver}.d/extensions/

	cp /etc/${php_ver}.d/php.ini.bak /etc/${php_ver}.d/php.ini
}

main() {
	download_src
	install_imagick_devel_pkg
	cd
	for i in php71 php72 php73
	do
		install_imagick_ext $i
	done

	cd $imagick_src
	tar -xzf imagick-3.4.4.tgz
	cd imagick-3.4.4
	/usr/local/php74/bin/phpize
	./configure --with-php-config=/usr/local/php74/bin/php-config
	make
	make install
	cp /etc/php7.d/extensions/50-imagick.ini /etc/php74.d/extensions/
}

main
