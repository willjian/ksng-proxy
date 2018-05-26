if [  'ja' = $WPLANG  ]; then
	DL_URL='https://ja.wordpress.org/latest-ja.tar.gz';
else
	DL_URL='https://wordpress.org/latest.tar.gz';
fi

wget -q -O /dev/null --spider $DL_URL
ret=$?

if [ $ret -eq 0 ] ; then
	mkdir /tmp/wp
	cd /tmp/wp
	wget -O 'wordpress.tar.gz' $DL_URL
	tar xzf ./wordpress.tar.gz
	mv ./wordpress/* /home/$CUSTOM_USER/$PROFILE/DocumentRoot
	rm -rf /tmp/wp

    cp -p /usr/lib/kusanagi/resource/wp-config-sample/$WPLANG/wp-config-sample.php /home/$CUSTOM_USER/$PROFILE/DocumentRoot/
else
    cp -r /usr/lib/kusanagi-wp/* /home/$CUSTOM_USER/$PROFILE/DocumentRoot
    cp -p /usr/lib/kusanagi/resource/wp-config-sample/en_US/wp-config-sample.php /home/$CUSTOM_USER/$PROFILE/DocumentRoot/
fi

#PREFIX=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1 | uniq`
cd /home/$CUSTOM_USER/$PROFILE/DocumentRoot
#/usr/bin/wp db create
#/usr/bin/wp core config --dbname="${DBNAME}" --dbuser="${DBUSER}" --dbpass="${DBPASS}" --dbhost=localhost --dbprefix="${PREFIX}_"
#/usr/bin/wp core install --url="${FDQN}" --title="${BLOGNAME}" --admin_user="${BLOGADMIN}" --admin_password="${BLOGPASS}" --admin_email="${BLOGMAIL}"
cp -rp /usr/lib/kusanagi/resource/DocumentRoot/* /home/$CUSTOM_USER/$PROFILE/DocumentRoot/
cp -p /usr/lib/kusanagi/resource/DocumentRoot/.htaccess /home/$CUSTOM_USER/$PROFILE/DocumentRoot/
cp -rp /usr/lib/kusanagi/resource/settings /home/$CUSTOM_USER/$PROFILE/
cp -rp /usr/lib/kusanagi/resource/tools /home/$CUSTOM_USER/$PROFILE/

# get Wordpress plugin
function get_wp_plugin {
	local PLUGIN_NAME=$1
	local JSON_URL="https://api.wordpress.org/plugins/info/1.0/${PLUGIN_NAME}.json"
	local WORK=/tmp/plugins.$$
	local PREVDIR=`pwd`
	mkdir $WORK
	cd $WORK
	wget -q -O /dev/null --spider $JSON_URL
	local PLUGIN_VER=
	if [ $? -eq 0 ]  ; then
		# get plugin download_link/version info from wordpress.org 
		local WORKFILE="plugin.json"
		wget -q -O ${WORKFILE} ${JSON_URL} 2> /dev/null
		local URL=`php -r 'echo json_decode(fgets(STDIN))->download_link;' < ${WORKFILE}`
		PLUGIN_VER=`php -r 'echo json_decode(fgets(STDIN))->version;' < ${WORKFILE}`
		ZIP=`basename $URL`
		wget -q -O /dev/null --spider $URL
		if [ $? -eq 0 ] ; then
			wget -q -O $ZIP $URL
			unzip -q $ZIP
			rm $ZIP
			# move ZIP file to PROFILE's plugin directory
			if [ -d $PLUGIN_NAME ] ; then
				mv $PLUGIN_NAME /home/$CUSTOM_USER/$PROFILE/DocumentRoot/wp-content/plugins
			else
				PLUGIN_VER=
			fi
			rm $WORKFILE
		fi
	fi
	cd $PREVDIR
	rmdir $WORK

	# echo empty string when cannot get plugins
	echo $PLUGIN_VER
}

# WooCommerce plugin
if [ $OPT_WOO ] ; then
	# get WooCommerce plugin
	WOOCOMMERCE_VERSION=`get_wp_plugin woocommerce`
	if [ -n $WOOCOMMERCE_VERSION ] ; then
		ACTIVE_PLUGINS="woocommerce/woocommerce.php"
		echo $(eval_gettext "Install WooCommerce plugin")

		KUSANAGI_DEFAULT_INI=/home/$CUSTOM_USER/$PROFILE/settings/kusanagi-default.ini

		# get Storefront theme
                SF_URL=http://api.wordpress.org/themes/info/1.0/
		SF_POST='action=theme_information&request=O:8:"stdClass":1:{s:4:"slug";s:10:"storefront";}'
		IS_SF_THEME=
		wget -q -O /dev/null --spider --post-data $SF_POST $SF_URL
		if [ $? -eq 0 ] ; then
			# get version info
			SF_DOWNLOAD=`wget -q -O - --post-data $SF_POST $SF_URL | \
			  php -r 'echo unserialize(fgets(STDIN))->download_link;'`
			SF_ZIP=storefront.zip
			wget -q -O /dev/null $SF_DOWNLOAD
			if [ $? -eq 0 ] ; then
				wget -O $SF_ZIP $SF_DOWNLOAD
				unzip -q $SF_ZIP
				rm $SF_ZIP
				mv storefront /home/$CUSTOM_USER/$PROFILE/DocumentRoot/wp-content/themes/
				echo $(eval_gettext "Install Storefront Theme")
				IS_SF_THEME=1
			fi
		fi
		if [ $IS_SF_THEME -ne 1 ] ; then
			echo $(eval_gettext "Cannot install Storefront Theme")
		fi

		cd

		if [  'ja' = $WPLANG  ]; then
			# get WooCommerce-for-japan plugin
			WCFJ_VERSION=`get_wp_plugin woocommerce-for-japan`
			if [ -n $WCFJ_VERSION ] ; then
				echo $(eval_gettext "Install WooCommerce for japan plugin")
				ACTIVE_PLUGINS="woocommerce-for-japan/woocommerce-for-japan.php $ACTIVE_PLUGINS"
			else
				echo $(eval_gettext "Cannot install WooCommerce for japan plugin")
			fi

			# get WooCommerce launguage pack when WPLANG=ja
			WOOCOMMERCE_JA_URL=https://downloads.wordpress.org/translation/plugin/woocommerce/${WOOCOMMERCE_VERSION}/ja.zip
			wget -q -O /dev/null --spider $WOOCOMMERCE_JA_URL
			if [ $? -eq 0 ] ; then
				WORK=/tmp/woo-language.$$
				mkdir $WORK
				cd $WORK
				wget $WOOCOMMERCE_JA_URL
				unzip -q ja.zip
				rm ja.zip
				mv ./* /home/$CUSTOM_USER/$PROFILE/DocumentRoot/wp-content/languages/plugins
				cd
				rmdir $WORK
				echo $(eval_gettext "Install WooCommerce japanese language file(\${WOOCOMMERCE_VERSION})")
			else
				echo $(eval_gettext "Cannot install WooCommerce japanese language file(\${WOOCOMMERCE_VERSION})")
			fi
			# install GMO payment plugins
			GMOPLUGIN="/usr/lib/kusanagi/resource/plugins/wc4jp-gmo-pg.1.2.0.zip"
			if [ -e $GMOPLUGIN ] ; then
				WORK=/tmp/gmo.$$
				mkdir $WORK
				cd $WORK
				unzip -q $GMOPLUGIN
				mv wc4jp-gmo-pg /home/$CUSTOM_USER/$PROFILE/DocumentRoot/wp-content/plugins/
				# rm -rf __MACOSX
				cd
				rm -rf $WORK
				ACTIVE_PLUGINS="wc4jp-gmo-pg/wc4jp-gmo-pg.php $ACTIVE_PLUGINS"
				echo $(eval_gettext "Install WooCommerce For GMO PG.")
			else
				echo $(eval_gettext "Cannot install WooCommerce For GMO PG.")
			fi
		fi

		# add initial install plugins setting to kusanagi-default.ini
		if [ -f $KUSANAGI_DEFAULT_INI ] ; then
			if [ "${ACTIVE_PLUGINS}" != "" ] ; then
				(echo -n active_plugins = \' 
				 echo -n ${ACTIVE_PLUGINS} | php -r 'echo serialize(explode(" ", fgets(STDIN)));' 
				 echo \' ) >> $KUSANAGI_DEFAULT_INI
			fi
			# for Storefront theme
			if [ $IS_SF_THEME -eq 1 ] ; then
				(echo "template = storefront"
				 echo "stylesheet = storefront") >> $KUSANAGI_DEFAULT_INI
			fi
		fi
	else
		echo $(eval_gettext "Cannot install WooCommerce plugin(\${WOOCOMMERCE_VERSION})")
	fi

fi

chown -R $CUSTOM_USER:$CUSTOM_USER /home/$CUSTOM_USER/$PROFILE
chmod 0777 /home/$CUSTOM_USER/$PROFILE/DocumentRoot
chmod 0755 /home/$CUSTOM_USER/$PROFILE/DocumentRoot/wp-content
chmod 0755 /home/$CUSTOM_USER/$PROFILE/DocumentRoot/wp-content/uploads
if [ ! -e /home/$CUSTOM_USER/$PROFILE/DocumentRoot/wp-content/languages ]; then
	mkdir /home/$CUSTOM_USER/$PROFILE/DocumentRoot/wp-content/languages
	#chown kusanagi.kusanagi /home/$CUSTOM_USER/$PROFILE/DocumentRoot/wp-content/languages
    chown $CUSTOM_USER:$CUSTOM_USER /home/$CUSTOM_USER/$PROFILE/DocumentRoot/wp-content/languages
fi
chmod 0777 -R /home/$CUSTOM_USER/$PROFILE/DocumentRoot/wp-content/languages
chmod 0777 -R /home/$CUSTOM_USER/$PROFILE/DocumentRoot/wp-content/plugins
sed -i "s/fqdn/$FQDN/g" /home/$CUSTOM_USER/$PROFILE/tools/bcache.clear.php

#Auto wordpress config
cd /home/$CUSTOM_USER/$PROFILE/DocumentRoot
mv wp-config-sample.php ../
cd ..
touch wp-config.php
sed 's/username_here/'$DBUSER'/' wp-config-sample.php | sed 's/password_here/'$DBPASS'/' | sed 's/database_name_here/'$DBNAME'/' | sed 's/kusanagi/'$CUSTOM_USER'/' > wp-config.php
chown -R $CUSTOM_USER:$CUSTOM_USER wp-config.php

