#!
get_php_ver() {
	for i in php7 php71 php72 php73 php74 php
	do
		if [ 0 -eq $(k_is_active $i-fpm.$1) ] ; then
			echo $i
		fi
	done
}

restart_php() {
	for i in php php71 php72 php73 php74
	do
		if [ 0 -eq $(k_is_enabled $i-fpm.$1) ] ; then
			systemctl restart $i-fpm.$1
		fi
	done
}
