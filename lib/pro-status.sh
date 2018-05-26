#!

## show brief provision information

function show_pro() {
	  if [ -n "$1" ]; then
	  	local exist=`grep PROFILE /etc/kusanagi.d/profile.conf | grep $1  2>/dev/null`
	  	if [ -n "$exist" ]; then
	  		php7=`grep '/var/cache/php7-fpm' /etc/nginx/conf.d/$1_http.conf | grep '#' 2>&1 > /dev/null;echo $?`
			php7s=`grep '/var/cache/php7-fpm' /etc/nginx/conf.d/$1_ssl.conf | grep '#' 2>&1 > /dev/null;echo $?`
			owner=`grep $1 /etc/kusanagi.d/profile.conf | grep DIR | cut -d '/' -f 3`
	  		if [ $php7 -eq 1 ]; then
	      			echo "PHP7-FPM is running for $1 HTTP traffic"
	  		else
	      			echo "HHVM is running for $1 HTTP traffic"
			fi
			if [ $php7s -eq 1 ]; then
			        echo "PHP7-FPM is running for $1 HTTPs traffic"
			else
			        echo "HHVM is running for $1 HTTPs traffic"
			fi
	  		HOME=`grep /$1 /etc/kusanagi.d/profile.conf | grep KUSANAGI_DIR | cut -d'=' -f2`
	  		echo "DocumentRoot = "$HOME  
		else
			echo "Provision $1 does not exist "
		fi	
	  else
	  	echo "No input ! Please enter any provision ! "
	  fi	
}
#show_pro $1
