## virt.sh
#ITEMS=("etc/monit.d/fqdn_nginx.conf" "etc/nginx/conf.d/fqdn_http.conf" "etc/nginx/conf.d/fqdn_ssl.conf" "etc/httpd/conf.d/fqdn_http.conf etc/httpd/conf.d/fqdn_ssl.conf")
ITEMS=("etc/nginx/conf.d/fqdn_http.conf" "etc/nginx/conf.d/fqdn_ssl.conf")
PROXY_CONF=("/etc/proxy/fqdn_http.conf.template" "/etc/proxy/fqdn_ssl.conf.template")
#PROFILE="www"
#FQDN="test.com"

local IS_ROOT_DOMAIN=$(is_root_domain $FQDN;echo $?)
local ADDFQDN=
if  [ "$IS_ROOT_DOMAIN" -eq 0 ]  ; then
	ADDFQDN="www.${KUSANAGI_FQDN}"
elif [ "$IS_ROOT_DOMAIN" -eq 1 ] ; then
	ADDFQDN=`echo $KUSANAGI_FQDN | cut -c 5-`
## K_handle in case domain does not exist
elif [ "$IS_ROOT_DOMAIN" -eq 2 ] ; then
	echo $FQDN | grep "^www\." >/dev/null 2>&1
	if [ "$?" -eq 0 ] ; then
		ADDFQDN=`echo $KUSANAGI_FQDN | cut -c 5-`
	else
		ADDFQDN="www.${KUSANAGI_FQDN}"
	fi
fi
## K_generate proxy configuration coresspond to each provision
for ITEM in ${PROXY_CONF[@]} ; do
	FILECONF=`echo $ITEM | sed "s/fqdn/$PROFILE/" |rev| cut -c 10- | rev`
	cp $ITEM $FILECONF
	sed -i -e "s/fqdn/$KUSANAGI_FQDN/g" $FILECONF
	if [ -n "$ADDFQDN" ] ; then
		sed -i -e "s/^\(\s*server_name\s\+.*\);/\1 ${ADDFQDN};/" $FILECONF
	fi
done
## update value of proxy_id, which is selected by provision, to proxy database
## by default, the first proxy is server hosting, proxy_id = 0
	pwrd=`cat /root/.my.cnf | grep password | cut -d '"' -f2`
	mysql -p$pwrd -e 'insert into proxy.pair (provision_name, proxy_id) values ("'$PROFILE'" , "0")' 

for ITEM in ${ITEMS[@]} ; do
	local RESOURCE="/usr/lib/kusanagi/resource"
	TARGET="/"`echo $ITEM | sed "s/fqdn/$PROFILE/"`
	if [ -f "$RESOURCE/${ITEM}.${APP}" ] ; then
		SOURCE="$RESOURCE/${ITEM}.${APP}"
	else
		SOURCE="$RESOURCE/${ITEM}"
	fi
	if [ -e $TARGET ]; then
		cp $TARGET ${TARGET}.bak
	fi
	echo $ITEM | grep -e httpd/conf.d -e nginx/conf.d 2>&1 > /dev/null 
	local RET=$?
	local PROV="# Common specific setting"
	cp $SOURCE $TARGET
	if [ $RET -eq 0 ]; then
	    if  [ -f "$RESOURCE/${ITEM}.${APP}.common" ] ; then
		     sed -i "/^$PROV start/r /dev/stdin" $TARGET < $RESOURCE/${ITEM}.${APP}.common
		     sed -i "/$PROV/d" $TARGET
		elif [ -f "$RESOURCE/${ITEM}.common" ] ; then
     	     sed -i "/^$PROV start/r /dev/stdin" $TARGET < $RESOURCE/${ITEM}.common
	         sed -i "/$PROV/d" $TARGET
	    fi
		if [ "$APP" = "Rails" ]; then
		    sed -i -e "s/secret_key_base/`/usr/local/bin/ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'`/" $TARGET
		fi
	fi	
    sed -i -e "s/profile/$PROFILE/g" -e "s/fqdn/$KUSANAGI_FQDN/g" -e "s/kusanagi_user/$KUSANAGI_USER/g" $TARGET

	if [ -n "$ADDFQDN" ] ; then
		if [[ $ITEM =~ ^etc/nginx/conf.d/ ]] ; then
			sed -i -e "s/^\(\s*server_name\s\+.*\);/\1 ${ADDFQDN};/" \
				-e "/# SSL ONLY/a\	# rewrite ^(.*)$ https:\/\/$ADDFQDN\$request_uri permanent; # SSL ONLY" $TARGET
		elif [[ $ITEM =~ ^etc/httpd/conf.d/ ]] ; then
			sed -i "/^\s\+ServerName\s/a\	ServerAlias ${ADDFQDN}" $TARGET
		fi
	fi
done

if [ "$APP" != "Rails" ] ; then
    # change path to /home/$CUSTOM_USER/$PROFILE
    mkdir -p /home/$CUSTOM_USER/$PROFILE/DocumentRoot
    # change nginx log path to other
    mkdir -p /var/log/$PROFILE/nginx
    mkdir -p /var/log/$PROFILE/httpd
    # change owner
	chown -R $CUSTOM_USER:$CUSTOM_USER /var/log/$PROFILE
	chown -R $CUSTOM_USER:$CUSTOM_USER /home/$CUSTOM_USER/$PROFILE
fi

if [ \! -e /usr/lib/kusanagi/lib/deploy-$APP.sh ] ; then
	echo $(eval_gettext "Cannot deploy \$APP")
	exit 1
fi

source /usr/lib/kusanagi/lib/deploy-$APP.sh

sed -i "s/^\(127.0.0.1.*\)\$/\1 $FQDN $ADDFQDN/" /etc/hosts || \
 (sed "s/\(^127.0.0.1.*$\)/\1 $FQDN $ADDFQDN/" /etc/hosts > /tmp/hosts.$$ && \
  cat /tmp/hosts.$$ > /etc/hosts && /usr/bin/rm /tmp/hosts.$$)
##
#if [ "$APP" != "Rails" ] && [ "$APP" != "WordPress" ]; then
#	if [ ! -f "/etc/systemd/system/hhvm.${CUSTOM_USER}.service" ]; then
#		/usr/src/create-hhvm-ini -d $CUSTOM_USER -u $CUSTOM_USER
#	elif [ `systemctl is-active hhvm.${CUSTOM_USER} | grep ^active 2>&1 >/dev/null;echo $?` -gt 0 ]; then 
#	    systemctl start hhvm.${CUSTOM_USER}
#		systemctl enable hhvm.${CUSTOM_USER}
#	fi
#	echo ""
#fi
## K_Add backup command for this provision
echo "/usr/src/backup -u $CUSTOM_USER -d $PROFILE" >> /etc/cron.daily/backup-prov
echo "/usr/src/cleanup-bk -u $CUSTOM_USER -d $PROFILE" >> /etc/cron.weekly/cleanbk-prov
## K_Update to dbuser-map file
/usr/src/dbuser-map-update $CUSTOM_USER

RET=0
# setting ssl cert files
#if [ "" != "$MAILADDR" ] && [ -e $CERTBOT ]; then
	# restart nginx or httpd server
	#k_restart nginx //comment for avoiding disconnection with cPanel
#	k_reload nginx
	# enable ssl
#	source $LIBDIR/ssl.sh
#	enable_ssl  $PROFILE $MAILADDR $FQDN
#	RET=$?
#	if [ $RET -eq 0 ] ; then
#		k_autorenewal --auto on
#	fi
#fi

if [ $RET -eq 0 ] ; then
	# reload services
	echo "---- Reload services ----"
	k_reload nginx httpd monit
	sleep 1
	k_monit_reloadmonitor
fi

