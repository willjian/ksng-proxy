#!

## show brief provision information

function sub_proc() {
	# input $2 is http or ssl
	php7=`grep '/var/cache/php7-fpm' /etc/nginx/conf.d/$1_$2.conf | grep '#' 2>&1 > /dev/null;echo $?`
	php5=`grep '/var/cache/php-fpm' /etc/nginx/conf.d/$1_$2.conf | grep '#' 2>&1 > /dev/null;echo $?`
	prov_=`echo ${1} | sed 's/\./\\\./'g`
	owner=`grep "/${prov_}\"" /etc/kusanagi.d/profile.conf | grep DIR | cut -d '/' -f 3`
	if [ $php7 -eq 1 ]; then
		ok=0
		for i in php71 php72 php73 php74
		do
			if [ 0 -eq $(k_is_active ${i}-fpm.$owner) ] ; then
				j=`echo $i | tr  '[a-z]' '[A-Z]'`
				echo "$j-FPM is running for $1 $2 traffic"
				ok=1
				break
			fi
		done
		if [ $ok -eq 0 ]; then
			echo "$1_$2.conf is using PHP7x-FPM socket but the service is OFF"
		fi
	fi
	if [ $php5 -eq 1 ]; then
		if [ 0 -eq $(k_is_active php-fpm.$owner) ] ; then
			echo "PHP-FPM is running for $1 $2 traffic"
		else
			echo "$1_$2.conf is using PHP-FPM socket but the service is OFF"
		fi
	fi
}


function show_pro() {
	  if [ -n "$1" ]; then
	  	prov_=`echo ${1} | sed 's/\./\\\./'g`
	  	local exist=`grep PROFILE /etc/kusanagi.d/profile.conf | grep "\"${prov_}\""  2>/dev/null`
	  	if [ -n "$exist" ]; then
			sub_proc $1 http
			sub_proc $1 ssl
	  		HOME=`grep "/${prov_}\"" /etc/kusanagi.d/profile.conf | grep KUSANAGI_DIR | cut -d'=' -f2`
	  		echo "DocumentRoot = "$HOME  
		else
			echo "Provision $1 does not exist "
		fi	
	  else
	  	echo "No input ! Please enter any provision ! "
	  fi	
}
#show_pro $1
