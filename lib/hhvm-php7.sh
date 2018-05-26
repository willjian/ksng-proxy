#!

function pro_php7() {
	 hhvm=`kusanagi pro_status $1 | grep HHVM 2>&1 > /dev/null; echo $?`
	 if [ $hhvm -eq 0 ]; then
	 	## edit nginx configuration
	 	owner=`grep $1 /etc/kusanagi.d/profile.conf | grep DIR | cut -d '/' -f 3`
	 	## disable using hhvm unix socket
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/hhvmd\/'$owner'.sock;*$\)/\t\t#\1/' /etc/nginx/conf.d/$1_http.conf
 	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/hhvmd\/'$owner'.sock;*$\)/\t\t#\1/' /etc/nginx/conf.d/$1_ssl.conf
     	## enable using php7-fpm unix socket
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php7-fpm\/'$owner'.sock;*$\)/\t\t\1/' /etc/nginx/conf.d/$1_http.conf
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php7-fpm\/'$owner'.sock;*$\)/\t\t\1/' /etc/nginx/conf.d/$1_ssl.conf
	 	## reload nginx configuration
	 	systemctl reload nginx
		## stop hhvm.owner service if there is no longer provision using it
		/usr/src/check_hhvm_exist $owner
	 else
	 	echo "PHP7-FPM is still running"
	 fi

 }

function pro_hhvm() {
	 hhvm=`kusanagi pro_status $1 | grep HHVM 2>&1 > /dev/null; echo $?`
	 if [ $hhvm -eq 1 ]; then
	 	## edit nginx configuration
	 	owner=`grep $1 /etc/kusanagi.d/profile.conf | grep DIR | cut -d '/' -f 3`
	 	## disable using php7-fpm unix socket
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php7-fpm\/'$owner'.sock;*$\)/\t\t#\1/' /etc/nginx/conf.d/$1_http.conf
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php7-fpm\/'$owner'.sock;*$\)/\t\t#\1/' /etc/nginx/conf.d/$1_ssl.conf
     	## enable using hhvm unix socket
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/hhvmd\/'$owner'.sock;*$\)/\t\t\1/' /etc/nginx/conf.d/$1_http.conf
	 	sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/hhvmd\/'$owner'.sock;*$\)/\t\t\1/' /etc/nginx/conf.d/$1_ssl.conf
    	##
		if [ ! -f "/etc/systemd/system/hhvm.${owner}.service" ]; then
			/usr/src/create-hhvm-ini -d ${owner} -u ${owner}
		elif [ `systemctl is-active hhvm.${owner} | grep ^active 2>&1 > /dev/null;echo $?` -gt 0 ]; then
			systemctl start hhvm.${owner}
			systemctl enable hhvm.${owner}
		fi	
	 	## reload nginx configuration
	 	systemctl reload nginx
	 else
	 	echo "HHVM is still running"
	 fi
}
