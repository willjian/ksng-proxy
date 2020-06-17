#!

function pro_php7() {
	 #hhvm=`kusanagi pro_status $1 | grep PHP-FPM > /dev/null 2>&1; echo $?`
	 hhvm=`grep -E '^\s*fastcgi_pass\s+unix:\/var\/cache\/php-fpm\/' /etc/nginx/conf.d/${1}_http.conf > /dev/null 2>&1; echo $?`
	 if [ $hhvm -eq 0 ]; then
	 	## edit nginx configuration
		prov_=`echo ${1} | sed 's/\./\\\./'g`
	 	owner=`grep "/${prov_}\"" /etc/kusanagi.d/profile.conf | grep DIR | cut -d '/' -f 3`
	 	## disable using php-fpm unix socket
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php-fpm\/'$owner'.sock;*$\)/\t\t#\1/' /etc/nginx/conf.d/$1_http.conf
 	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php-fpm\/'$owner'.sock;*$\)/\t\t#\1/' /etc/nginx/conf.d/$1_ssl.conf
     	## enable using php7-fpm unix socket
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php7-fpm\/'$owner'.sock;*$\)/\t\t\1/' /etc/nginx/conf.d/$1_http.conf
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php7-fpm\/'$owner'.sock;*$\)/\t\t\1/' /etc/nginx/conf.d/$1_ssl.conf

	 	## reload nginx configuration
	 	systemctl reload nginx
	 else
	 	echo "PHP7-FPM is still running"
	 fi

 }

function pro_hhvm() {
	 hhvm=`grep -E '^\s*fastcgi_pass\s+unix:\/var\/cache\/php-fpm\/' /etc/nginx/conf.d/${1}_http.conf > /dev/null 2>&1; echo $?`
	 if [ $hhvm -eq 1 ]; then
	 	## edit nginx configuration
		prov_=`echo ${1} | sed 's/\./\\\./'g`
	 	owner=`grep "/${prov_}\"" /etc/kusanagi.d/profile.conf | grep DIR | cut -d '/' -f 3`
	 	## disable using php7-fpm unix socket
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php7-fpm\/'$owner'.sock;*$\)/\t\t#\1/' /etc/nginx/conf.d/$1_http.conf
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php7-fpm\/'$owner'.sock;*$\)/\t\t#\1/' /etc/nginx/conf.d/$1_ssl.conf
     	## enable using php-fpm unix socket
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php-fpm\/'$owner'.sock;*$\)/\t\t\1/' /etc/nginx/conf.d/$1_http.conf
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php-fpm\/'$owner'.sock;*$\)/\t\t\1/' /etc/nginx/conf.d/$1_ssl.conf
        ##
		if [ $(k_is_active php-fpm.${owner}) -gt 0 ]; then
			systemctl start php-fpm.${owner}
			systemctl enable php-fpm.${owner}
		fi
	 	## reload nginx configuration
	 	systemctl reload nginx
	 else
	 	echo "PHP-FPM is still running"
	 fi
}
