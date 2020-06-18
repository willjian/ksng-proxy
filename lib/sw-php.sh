#!
# script to update php of all provisions
check_nginx_valid() {
    nginx -t > /dev/null 2>&1;echo $?
}

get_user() {
	local prov=$1
	prov_=`echo ${1} | sed 's/\./\\\./'g`
	user_=`grep "/${prov_}\"" /etc/kusanagi.d/profile.conf | grep DIR | cut -d '/' -f 3`
	if [ -z ${user_} ]; then
		pass=$(cat /usr/src/.bk_user_dwp)
		user_=$(mysql -ubk_user -p$pass kusanagi -e "select user_name from provision where provision_name = '$prov'" | tail -n +2)
	fi
	echo $user_
}

function sw_php() {
	# $1 is provision name
	# $2 is desired php version
	## edit nginx configuration
	owner=$(get_user $1)
	if [ ! -z ${owner} ]; then
		if [[ "$2" =~ ^(php71|php72|php73|php74)$ ]]; then
			## enable php7-fpm unix socket
			sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php7-fpm\/'$owner'.sock;.*$\)/\t\t\t\1/' /etc/nginx/conf.d/${1}_http.conf
			sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php7-fpm\/'$owner'.sock;.*$\)/\t\t\t\1/' /etc/nginx/conf.d/${1}_ssl.conf
			## disable php-fpm unix socket
			sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php-fpm\/'$owner'.sock;.*$\)/\t\t\t#\1/' /etc/nginx/conf.d/${1}_http.conf
			sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php-fpm\/'$owner'.sock;.*$\)/\t\t\t#\1/' /etc/nginx/conf.d/${1}_ssl.conf
		fi
		if [ "$2" = "php" ]; then
			## enable php-fpm unix socket
			sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php-fpm\/'$owner'.sock;.*$\)/\t\t\t\1/' /etc/nginx/conf.d/${1}_http.conf
			sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php-fpm\/'$owner'.sock;.*$\)/\t\t\t\1/' /etc/nginx/conf.d/${1}_ssl.conf
			## disable php7-fpm unix socket
			sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php7-fpm\/'$owner'.sock;.*$\)/\t\t\t#\1/' /etc/nginx/conf.d/${1}_http.conf
			sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/php7-fpm\/'$owner'.sock;.*$\)/\t\t\t#\1/' /etc/nginx/conf.d/${1}_ssl.conf
		fi
		## disable hhvm unix socket
		sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/hhvmd\/'$owner'.sock;.*$\)/\t\t\t#\1/' /etc/nginx/conf.d/${1}_http.conf
		sed -i 's/^.*\(fastcgi_pass unix:\/var\/cache\/hhvmd\/'$owner'.sock;.*$\)/\t\t\t#\1/' /etc/nginx/conf.d/${1}_ssl.conf
	else
		exit 1
	fi
	## reload nginx configuration
	#systemctl reload nginx
 }
