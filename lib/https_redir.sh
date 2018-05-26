source /usr/src/list_proxy_by_pairs
function k_https() {
	#All HTTPS or not
	local fqdn=$(k_get_fqdn $PROFILE)
	local opt=$1
	local arg=$2
	local OLDPROTO PROTO
	if [ "$arg" = "redirect" ] ; then
		echo $(eval_gettext "Set redirect all traffic on FQDN to HTTPS.(Permanently)") | sed "s|FQDN|$fqdn|"
		sed -i "s/\(\s\+\)#\s*rewrite ^(.*)$ https:/\1rewrite ^(.*)$ https:/g" $NGINX_HTTP
		## edit proxy http
		sed -i "s/\(\s\+\)#\s*return 301 https:/\1return 301 https:/g" /etc/proxy/${fqdn}_http.conf

		current_id=`mysql -upr0xy -pPasSw0rd -e "select proxy_id from proxy.pair where provision_name = '$fqdn'" | tail -n 1`
		let i=${current_id}-1
		[ $current_id -gt 0 ] && rsync -avzhe 'ssh -p1010' /etc/proxy/${fqdn}_http.conf root@proxy${current_id}:/etc/nginx/conf.d/
		[ $current_id -gt 0 ] && rsync -avzhe 'ssh -p1010' /etc/proxy/${fqdn}_http.conf root@proxy${proxy_pair[$i]}:/etc/nginx/conf.d/
		##
		sed -i "s/RewriteEngine Off/RewriteEngine On/g" $HTTPD_HTTP
		if [ -f "$WPCONFIG" ] ; then
			sed -i "s/^[#\s]\+define('FORCE_SSL_ADMIN/define('FORCE_SSL_ADMIN/g" $WPCONFIG
		fi
		OLDPROTO="http://"
		PROTO="https://"
	elif [ "$arg" = "noredirect" ] ; then
		echo $(eval_gettext "Release redirect all traffic on FQDN to HTTPS.") | sed "s|FQDN|$fqdn|"
		sed -i "s/\(\s\+\)rewrite ^(.*)$ https:/\1#rewrite ^(.*)$ https:/g" $NGINX_HTTP
		## edit proxy http
		sed -i "s/\(\s\+\)return 301 https:/\1#return 301 https:/g" /etc/proxy/${fqdn}_http.conf

		current_id=`mysql -upr0xy -pPasSw0rd -e "select proxy_id from proxy.pair where provision_name = '$fqdn'" | tail -n 1`
		let i=${current_id}-1
		[ $current_id -gt 0 ] && rsync -avzhe 'ssh -p1010' /etc/proxy/${fqdn}_http.conf root@proxy${current_id}:/etc/nginx/conf.d/
		[ $current_id -gt 0 ] && rsync -avzhe 'ssh -p1010' /etc/proxy/${fqdn}_http.conf root@proxy${proxy_pair[$i]}:/etc/nginx/conf.d/
		##
		sed -i "s/RewriteEngine On/RewriteEngine Off/g" $HTTPD_HTTP
		if [ -f "$WPCONFIG" ] ; then
			sed -i "s/^define('FORCE_SSL_ADMIN/#define('FORCE_SSL_ADMIN/g" $WPCONFIG
		fi
		OLDPROTO="https://"
		PROTO="http://"
	else
		echo $(eval_gettext "Cannot use \$arg.")
		echo $(eval_gettext "kusanagi \$opt [redirect|noredirect].")
		return 1
	fi

	# for WordPress
	if [ "WordPress" = "${KUSANAGI_TYPE:-}" ] ; then
		DOC_ROOT="$KUSANAGI_DIR/DocumentRoot"
		WP="sudo -u kusanagi -i -- /usr/local/bin/wp"
		$WP search-replace $OLDPROTO$fqdn $PROTO$fqdn --path=$DOC_ROOT --all-tables > /dev/null
	fi
}
