#!
source /usr/src/list_proxy_by_pairs
function k_readkey_yn() {
	local MSG="$@"
	while :
	do
		echo -n $MSG" " 1>&2
		read usekey
		if [ -z "$usekey" ] ; then
			:
		elif [ ${usekey,,} = 'y' ] ; then
			echo 1
			break
		elif [ ${usekey,,} = 'n' ] ; then
			break
		fi
	done
}
check_lets_existed()
{
    if [ -d "/etc/letsencrypt/archive/${1}" ]; then
        echo 1
    else
        if [ 0 -eq $(ls /etc/letsencrypt/archive/${1}-* > /dev/null 2>&1;echo $?) ]; then
            echo 1
        else
            echo 0
        fi
    fi
}
function k_remove() {
	local _PROV=1
	local YESFLAG=
	local TARGET=
	for OPT in "$@"
	do
		# skip 1st argment "setting"
		if [ $_PROV ] ; then
			_PROV=
		else
			case "$OPT" in
				'-y')
					YESFLAG=1
				;;
				'--*')
					echo $(eval_gettext "Cannot use option \$OPT")
					return 1
				;;
				*)
					if [ -z "${TARGET}" ] ; then
						TARGET=$OPT
					fi
				;;
			esac
		fi
	done

	if [ -z $TARGET ] ; then
		TARGET=$PROFILE
	fi
	k_read_profile $TARGET

	# select delete modules
	local REMOVE_CONTENT=
	local REMOVE_CONFIG=
	local REMOVE_DATABASE=
	if [ $YESFLAG ] ; then
		REMOVE_CONTENT=1
		REMOVE_CONFIG=1
		[ -n "$KUSANAGI_DBNAME" ] && REMOVE_DATABASE=1
	else
		REMOVE_CONFIG=$(k_readkey_yn $(eval_gettext "Remove \$TARGET config files ? [y/n] "))
		REMOVE_CONTENT=$(k_readkey_yn $(eval_gettext "Remove $KUSANAGI_DIR and /var/log/\$TARGET directory ? [y/n] "))
		[ -n "$KUSANAGI_DBNAME" ] && REMOVE_DATABASE=$(k_readkey_yn $(eval_gettext "Remove \$TARGET database ? [y/n] "))
	fi

	# remove config file
	if [ $REMOVE_CONFIG ] ; then
		# remove files
		for file in $NGINX_HTTP $NGINX_HTTPS $HTTPD_HTTP $HTTPD_HTTPS \
				"/etc/monit.d/${TARGET}_nginx.conf" "/etc/monit.d/${TARGET}_httpd.conf"
		do
			[ -f $file ] && rm $file
		done
		local IS_ROOT_DOMAIN=$(is_root_domain $KUSANAGI_FQDN;echo $?)
		local ADDFQDN=
		if  [ "$IS_ROOT_DOMAIN" -eq 0 ]  ; then
			ADDFQDN="www.${KUSANAGI_FQDN}"
		elif [ "$IS_ROOT_DOMAIN" -eq 1 ] ; then
			ADDFQDN=`echo $KUSANAGI_FQDN | cut -c 5-`
		fi
		# hosts
		sed -i "s/\s\+$KUSANAGI_FQDN\(\s*\)/\1/g" /etc/hosts
		if [ -n "$ADDFQDN" ] ; then
			sed -i "s/\s\+$ADDFQDN\(\s*\)/\1/g" /etc/hosts
		fi
	fi

	echo "Removing "$KUSANAGI_DIR" directory ..."
	# remove content
	if [ $REMOVE_CONTENT ] ; then
		rm -rf $KUSANAGI_DIR
		rm -rf /var/log/${TARGET}
	fi
	# remove backup command
	sed -i '/d '$TARGET'$/d' /etc/cron.daily/backup-prov
	sed -i '/d '$TARGET'$/d' /etc/cron.weekly/cleanbk-prov
	# remove proxy configuration corresponding
	rm -f /etc/proxy/${TARGET}"_"*
	# remove proxy_id entry
	pwrd=`cat /root/.my.cnf | grep password | cut -d '"' -f2`
	current_id=`mysql -p$pwrd -e "select proxy_id from proxy.pair where provision_name = '${TARGET}'" | tail -n 1`
	let i=${current_id}-1
	[ $current_id -gt 0 ] && ssh -p1010 root@proxy${current_id} 'rm -f /etc/nginx/conf.d/'${TARGET}'_*'
	[ $current_id -gt 0 ] && ssh -p1010 root@proxy${proxy_pair[$i]} 'rm -f /etc/nginx/conf.d/'${TARGET}'_*'
	mysql -p$pwrd -e "delete from proxy.pair where provision_name = '${TARGET}'"
	# kld_remove lets cert
	if [ 1 -eq $(check_lets_existed $KUSANAGI_FQDN) ]; then
		if [ -d "/etc/letsencrypt/archive/$KUSANAGI_FQDN" ]; then
	        mv /etc/letsencrypt/archive/$KUSANAGI_FQDN /opt/maintenance/lets_tools/archive.deleted/
	        mv /etc/letsencrypt/live/$KUSANAGI_FQDN /opt/maintenance/lets_tools/live.deleted/
	    fi
		if [ 0 -eq $(ls /etc/letsencrypt/archive/${KUSANAGI_FQDN}-* > /dev/null 2>&1;echo $?) ]; then
		    mv /etc/letsencrypt/archive/${KUSANAGI_FQDN}-* /opt/maintenance/lets_tools/archive.deleted/
		    mv /etc/letsencrypt/live/${KUSANAGI_FQDN}-* /opt/maintenance/lets_tools/live.deleted/
		fi
		if [ -f "/etc/letsencrypt/renewal/${KUSANAGI_FQDN}.conf" ]; then
            mv /etc/letsencrypt/renewal/${KUSANAGI_FQDN}.conf /opt/maintenance/lets_tools/recycle_bin/
        fi
        if [ 0 -eq  $(ls /etc/letsencrypt/renewal/${KUSANAGI_FQDN}-*.conf >/dev/null 2>&1;echo $?) ]; then
            mv /etc/letsencrypt/renewal/${KUSANAGI_FQDN}-*.conf /opt/maintenance/lets_tools/recycle_bin/
        fi
	fi
	# remove db
	if [ $REMOVE_DATABASE ] ; then
		local DB_ROOT_PASS=$(get_db_root_password)
		echo "drop database \`$KUSANAGI_DBNAME\`;" | mysql -uroot -p"$DB_ROOT_PASS"
		echo "delete from mysql.user where User = '$KUSANAGI_DBUSER';" | mysql -uroot -p"$DB_ROOT_PASS"
	fi

	# remove profile
	if [ -n "${TARGET}" ] ; then
		k_write_profile $TARGET '' remove
		if [ -f /etc/kusanagi.conf ] && \
				[ 0 -eq $(grep $TARGET /etc/kusanagi.conf 2>&1 > /dev/null; echo $?) ] ; then
			local LAST=$(awk '/^\[/ {gsub(/^\[|\]$/, ""); a=$0} END {print a}' /etc/kusanagi.d/profile.conf)
			echo "PROFILE=\"$LAST\"" > /etc/kusanagi.conf
		fi
	fi

}
