# KUSANAGI INIT
# 2015/07/21
# version 1.0.3

function k_provision {
	local OPT_WOO=	# use WooCommerce option(1 = use/other no use)
	local OPT_WPLANG OPT_FQDN OPT_EMAIL OPT_DBNAME OPT_DBUSER OPT_DBPASS OPT_NO_EMAIL OPT_CUSTOM_USER
	local WPLANG= FQDN= MAILADDR= DBNAME= DBUSER= DBPASS= CUSTOM_USER=
	local OPT PRE_OPT
	local APP='WordPress'
	## perse arguments
	shift
	for OPT in "$@"
	do
		# skip 1st argment "provision"
		if [ $OPT_WPLANG ] ; then
			if [ "$OPT" =  "en_US" -o "$OPT" = "ja" ] ; then
				WPLANG="$OPT"
				OPT_WPLANG=
			else
				echo $(eval_gettext "option \$PRE_OPT \$OPT: please input 'en_US' or 'ja'.")
				return 1
			fi
		elif [ $OPT_FQDN ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{3,}$ ]]; then
				FQDN="$OPT"
				OPT_FQDN=
			else
				echo $(eval_gettext "option \$PRE_OPT \$OPT: please input [a-zA-Z0-9._-] 3 characters minimum.")
				return 1
			fi
		elif [ $OPT_EMAIL ] ; then
			if [[ "${OPT,,}" =~ ^[a-z0-9!$\&*.=^\`|~#%\'+\/?_{}-]+@([a-z0-9_-]+\.)+(xx--[a-z0-9]+|[a-z]{2,})$ ]] ; then #'`
				MAILADDR="$OPT"
				OPT_EMAIL=
			else
				echo $(eval_gettext "option \$PRE_OPT \$OPT: please input Valid email address.")
				return 1
			fi
		elif [ $OPT_DBNAME ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{3,64}$ ]]; then
				DBNAME="$OPT"
				OPT_DBNAME=
			else
				echo $(eval_gettext "option \$PRE_OPT \$OPT: please input [a-zA-Z0-9._-] 3 to 64 characters.")
				return 1
			fi
		elif [ $OPT_DBUSER ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9._-]{3,16}$ ]] ; then
				DBUSER="$OPT"
				OPT_DBUSER=
			else
				echo $(eval_gettext "Enter username for database. USE [a-zA-Z0-9.!#%+_-] 3 to 16 characters.")
				return 1
			fi
		elif [ $OPT_DBPASS ] ; then
			if [[ "$OPT" =~ ^[a-zA-Z0-9\.\!\#\%\+\_\-]{8,}$ ]] ; then
				DBPASS="$OPT"
				OPT_DBPASS=
			else
				echo $(eval_gettext "Enter password for database user 'DBUSER'. USE [a-zA-Z0-9.!#%+_-] 8 characters minimum.")
				return 1
			fi
		elif [ $OPT_CUSTOM_USER ] ; then
			if [ -d "/home/$OPT" ]; then
		        CUSTOM_USER="$OPT"
		        OPT_CUSTOM_USER=
		    else
		        echo $(eval_gettext "No input or non-existing user . Please enter an existing user.")
		        return 1
		    fi
		else
			case "${OPT}" in
			'--woo'|'--WooCommerce')
				OPT_WOO=1
				;;
			'--wordpress'|'--WordPress')
				APP='WordPress'
				;;
			'--c5'|'--concrete5')
				APP='concrete5'
				;;
			'--lamp'|'--LAMP')
				APP='lamp'
				;;
			'--drupal'|'--drupal8')
				APP='drupal8'
				;;
			'--rails'|'--RubyonRails')
			    APP='Rails';
			    k_rails_init;
			    ;;
			'--wplang')
				OPT_WPLANG=1
				;;
			'--fqdn')
				OPT_FQDN=1
				;;
			'--email')
				OPT_EMAIL=1
				;;
			'--no-email'|'--noemail')
				OPT_NO_EMAIL=1
				;;
			'--dbname')
				OPT_DBNAME=1
				;;
			'--dbuser')
				OPT_DBUSER=1
				;;
			'--dbpass')
				OPT_DBPASS=1
				;;
			'--custom-user')
			    OPT_CUSTOM_USER=1
			    ;;

			-*)				# skip other option
				echo $(eval_gettext "Cannot use option \$OPT")
				return 1
				;;
			*)
				NEW_PROFILE="$OPT"
				break			# enable 1st (no option) string
			esac
		fi
		PRE_OPT=$OPT
	done
	
	

	# DB Root Password
	local DB_ROOT_PASS=`get_db_root_password`
	if [ -z "$DB_ROOT_PASS" ] ; then
		echo $(eval_gettext "Faild. DB Root password cannot get.")
		return 1
	fi
	
	# for config
	KUSANAGI_TYPE=$APP
	#KUSANAGI_DIR=$TARGET_DIR
	
	if [ "WordPress" = $APP ]; then
		## lang
		if [ -z "$WPLANG" ] ; then
			echo -n $(eval_gettext "Choose the installation language of WordPress.")
			echo
			echo $(eval_gettext "1 : en_US")
			echo $(eval_gettext "2 : ja")
			echo
			echo $(eval_gettext "q : quit")
			echo 
			echo -n $(eval_gettext "Which do you choose?: ")" "
			while :
			do
				read WPLANG_NUM 
				case "$WPLANG_NUM" in
				"1" )
					echo
					echo $(eval_gettext "You choose: en_US")
					WPLANG="en_US"
					break
					;;
				"2" )
					echo
					echo $(eval_gettext "You choose: ja")
					WPLANG="ja"
					break
					;;
				"q" )
					echo
					echo $(eval_gettext "Exit.")
					return 1
					break
					;;
				* ) 
					echo $(eval_gettext "Please select")
					echo
					echo $(eval_gettext "1 : en_US")
					echo $(eval_gettext "2 : ja")
					echo
					echo $(eval_gettext "q : quit")
					echo
					echo -n $(eval_gettext "Which you want?: ")" "
					;;
				esac
			done
		fi
	fi
	
	## kusanagi user password
	
	## custom_user
	while [ "$CUSTOM_USER" = "" ]; do
	    echo
	    echo $(eval_gettext "Enter an existing user whose home directory you want to put your web under.") 
	    read  LINE1
		echo $(eval_gettext "Re-type it.")
		read  LINE2
		if [ "$LINE1" = "$LINE2" ]; then
		    if [ -d "/home/$LINE1" ]; then
	           CUSTOM_USER="$LINE1"
			fi
		fi
    done
	
	## fqdn
	while [ "$FQDN" = "" ]; do
		echo
		echo $(eval_gettext "Enter hostname(fqdn) for your website. ex) kusanagi.tokyo")
		read LINE1
		echo $(eval_gettext "Re-type hostname(fqdn) for your website.")
		read LINE2
		if [ "$LINE1" = "$LINE2" ] && [[ $LINE1 =~ ^[a-zA-Z0-9._-]{3,}$ ]]; then
			FQDN="$LINE1"
		fi
	done
	
	## mailaddress for let's encrypt
	
	LINE1=""
	LINE2="dummy"
	if [ -z "$MAILADDR" -a -z "$OPT_NO_EMAIL" ] ; then
		while [ "$LINE1" != "$LINE2" ]; do
			echo
			echo $(eval_gettext "In order to use Let's Encrypt services, you must agree to Let's Encrypt's Term of Services.")
			echo $(eval_gettext "If you agree to this TOS, type your email address; if not, hit enter twice.")
			echo $(eval_gettext "TOS of Let's Encrypt : https://letsencrypt.org/repository/")
			read LINE1
			echo $(eval_gettext "Re-type mail address.")
			read LINE2
			if [ "$LINE1" = "$LINE2" ] && \
					[ "" != "$LINE1" ] && \
					[[ "${LINE1,,}" =~ ^[a-z0-9!$\&*.=^\`|~#%\'+\/?_{}-]+@([a-z0-9_-]+\.)+(xx--[a-z0-9]+|[a-z]{2,})$ ]] ; then #'`
				MAILADDR="$LINE1"
			fi
		done
	fi
	
	## database
	
	while [ "$DBNAME" = "" ]; do
		echo 
		echo $(eval_gettext "Enter the name of your database.")
		read LINE1
		echo $(eval_gettext "Re-type database name you create.")
		read LINE2
		if [ "$LINE1" = "$LINE2" ] && [[ $LINE1 =~ ^[a-zA-Z0-9._-]{3,64}$ ]]; then
			DBNAME="$LINE1"
		fi
	done

	# DB already check
	echo 'show databases' | mysql -uroot -p"$DB_ROOT_PASS" | fgrep -w $DBNAME > /dev/null
	if [ $? -eq 0 ] ; then
		echo $(eval_gettext "That database(\$DBNAME) already exists.")
		return 1
	fi
	
	## db user
	
	while [ "$DBUSER" = "" ]; do
		echo 
		echo $(eval_gettext "Enter user name for database DBNAME.") \
				| sed "s|DBNAME|$DBNAME|"
		read LINE1
		echo $(eval_gettext "Re-type user name for database DBNAME") \
				| sed "s|DBNAME|$DBNAME|"
		read LINE2
		if [ "$LINE1" = "$LINE2" ] && [[ $LINE1 =~ ^[a-zA-Z0-9._-]{3,16}$ ]]; then
			DBUSER="$LINE1"
		fi
	done
	
	# DB user already check
	echo "SELECT User FROM mysql.user" | mysql -uroot -p"$DB_ROOT_PASS" | fgrep -w $DBUSER > /dev/null
	if [ "$?" -eq 0 ] ; then
		echo $(eval_gettext "That user(DBUSER) existing on DB. so exiting.") \
				| sed "s|DBUSER|$DBUSER|"
		return 1
	fi

	## db user password
	while [ "$DBPASS" = "" ]; do
		echo 
		echo $(eval_gettext "Enter password for database user 'DBUSER'. USE [a-zA-Z0-9.!#%+_-] 8 characters minimum.") \
				| sed "s|DBUSER|$DBUSER|"
		read -s LINE1
		echo $(eval_gettext "Re-type password for database user 'DBUSER'.") \
				| sed "s|DBUSER|$DBUSER|"
		read -s LINE2
		if [ "$LINE1" = "$LINE2" ] && [[ $LINE1 =~ ^[a-zA-Z0-9.\!\#\%\+_-]{8,}$ ]]; then
			DBPASS="$LINE1"
		fi
	done

	


	# Create DB
	echo "CREATE DATABASE IF NOT EXISTS \`$DBNAME\`" | mysql -uroot -p"$DB_ROOT_PASS"
	#echo "----"
	
	echo "GRANT ALL PRIVILEGES ON \`$DBNAME\`.* TO '$DBUSER'@'localhost' IDENTIFIED BY '$DBPASS'" | mysql -uroot -p"$DB_ROOT_PASS"
	echo "FLUSH PRIVILEGES" | mysql -uroot -p"$DB_ROOT_PASS"
	
	## check profile name and directory 
	
	if [[ ! $NEW_PROFILE =~ ^[a-zA-Z0-9._-]{3,24}$ ]]; then
		echo $(eval_gettext "Failed. Profile name requires [a-zA-Z0-9._-] 3-24 characters.")
		return 1
	fi
	
    # TARGET_DIR=/home/kusanagi/$NEW_PROFILE
	# Change target_dir to /home/$CUSTOM_USER/$NEW_PROFILE
	TARGET_DIR=/home/$CUSTOM_USER/$NEW_PROFILE
	echo $(eval_gettext "Target directory is TARGET_DIR.") | sed "s|TARGET_DIR|$TARGET_DIR|"
	
	if [ -e $TARGET_DIR ]; then
		echo $(eval_gettext "Failed. Target directory already exists.")
		return 1
	fi
	local new_profile_=`echo $NEW_PROFILE | sed 's/\./\\\./g'`
	if [ -f /etc/kusanagi.d/profile.conf ] && \
			[ 0 -eq $(grep -w "^\[$new_profile_\]" /etc/kusanagi.d/profile.conf 2>&1 > /dev/null ; echo $?) ] ; then
		echo $(eval_gettext "Failed. Profile name(NEW_PROFILE) is already used.") | sed "s|NEW_PROFILE|$NEW_PROFILE|"
		return 1
	fi
	
	PROFILE=$NEW_PROFILE
	KUSANAGI_FQDN=$FQDN
	KUSANAGI_DBNAME=$DBNAME
	KUSANAGI_DBUSER=$DBUSER
	KUSANAGI_DBPASS=$DBPASS
	#TARGET_DIR=/home/$CUSTOM_USER/$NEW_PROFILE
	KUSANAGI_DIR=$TARGET_DIR
	#add more global variable
	KUSANAGI_USER=$CUSTOM_USER
	# write to config file
	k_write_profile $PROFILE
	NGINX_HTTP="/etc/nginx/conf.d/${PROFILE}_http.conf"
	NGINX_HTTPS="/etc/nginx/conf.d/${PROFILE}_ssl.conf"
	HTTPD_HTTP="/etc/httpd/conf.d/${PROFILE}_http.conf"
	HTTPD_HTTPS="/etc/httpd/conf.d/${PROFILE}_ssl.conf"

	source /usr/lib/kusanagi/lib/virt.sh
	
	source /etc/kusanagi.conf
	
	if [ "$PROFILE" = "" ]; then
		echo 'PROFILE="'$NEW_PROFILE'"' > /etc/kusanagi.conf
	fi
	
	echo $(eval_gettext "Provisioning of NEW_PROFILE completed. Access FQDN and install APP!") \
			| sed -e "s|NEW_PROFILE|$NEW_PROFILE|" -e "s|FQDN|$FQDN|" -e "s|APP|$APP|"
	
	return 0
}
