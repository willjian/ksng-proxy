# ---
# KUSANAGI functions
# /usr/bin/kusanagi 専用ライブラリ
# ---
# 2015/07/21 Ver. 1.0.3

PROFILECONF=/etc/kusanagi.d/profile.conf
CERTBOT=/usr/local/certbot/certbot-auto

function check_status() {
	# 直前のコマンドの戻り値により、'Done.'または'Failed.'を表示する。
	# デーモンの起動など行った際にはコールすること。
	# ${_RETURN}は、exitの引数に付けてください。

	if [ "$?" -eq 0 ]; then
	  _RETURN=0
	  echo $(eval_gettext "Done.")
	else
	  _RETURN=1
	  echo $(eval_gettext "Failed.")
	fi
}

function check_profile() {
	if [ "$PROFILE" = "" ]; then
		echo $(eval_gettext "No Profile exists.")
		exit
	else
		k_read_profile $PROFILE
	fi
}

function k_read_profile() {
	PROFILE=$1
	local DONTWRITE=${2:-}
	local INIFILE=${3:-$PROFILECONF}
	if [ -f $INIFILE ] ; then
		# load from inifile
		eval $(awk "/^\[.+\]/ {p = 0 } /^\[$PROFILE\]/ { p = 1 } p == 1" $INIFILE | \
			awk '$1 ~ /^.+=.+$/ {print $1} ')
	fi
	local CUSTOM_USER=`grep '\['$PROFILE'\]' $PROFILECONF -A 10 | grep KUSANAGI_USER | cut -d '"' -f2`
	# set uninitialized value
	local IS_WRITABLE=0
	if [[ ! -v KUSANAGI_DIR ]] ; then
		KUSANAGI_DIR=/home/$CUSTOM_USER/$PROFILE
		if [ ! -d $KUSANAGI_DIR ] ; then
			echo -n  $(eval_gettext "Target profile(\$PROFILE) not found.")
			echo $(eval_gettext "\$KUSANAGI_DIR not found")
			exit 1
		fi
		IS_WRITABLE=1
	fi
	if [[ ! -v KUSANAGI_FQDN ]] ; then
		KUSANAGI_FQDN=$(k_get_fqdn $PROFILE)
		if [ "$KUSANAGI_FQDN" = "" ] ; then
			echo -n  $(eval_gettext "Target profile(\$PROFILE) not found.")
			echo $(eval_gettext "FQDN cannot get")
			exit 1
		fi
		IS_WRITABLE=1
	fi
	if [[ ! -v KUSANAGI_TYPE ]] ; then
		KUSANAGI_TYPE=WordPress
		IS_WRITABLE=1
	fi

	NGINX_HTTP="/etc/nginx/conf.d/${PROFILE}_http.conf"
	NGINX_HTTPS="/etc/nginx/conf.d/${PROFILE}_ssl.conf"
	HTTPD_HTTP="/etc/httpd/conf.d/${PROFILE}_http.conf"
	HTTPD_HTTPS="/etc/httpd/conf.d/${PROFILE}_ssl.conf"

	#TARGET_DIR=/home/kusanagi/$PROFILE
	TARGET_DIR=/home/$CUSTOM_USER/$PROFILE
	if [ "$KUSANAGI_TYPE" = "WordPress" ] ; then
		if [ -e $TARGET_DIR/wp-config.php ]; then
			WPCONFIG="$TARGET_DIR/wp-config.php"
		elif [ -e $TARGET_DIR/DocumentRoot/wp-config.php ]; then
			WPCONFIG="$TARGET_DIR/DocumentRoot/wp-config.php"
		else
			WPCONFIG=""
		fi
	fi

	if [ -z $DONTWRITE ] && [ $IS_WRITABLE -eq 1 ] ; then
		k_write_profile $PROFILE
	fi
}

function k_write_profile() {
	local PROFILE=$1
	local INIFILE=${2:-$PROFILECONF}
	local REMOVE=${3:-no} # unless set no(default), remove PROFILE

	local WORK=$(mktemp)
	if [ -f $PROFILECONF ] ; then
		awk "BEGIN { p = 1 } /^\[.+\]/ { p = 1 } /^\[$PROFILE\]/ { p = 0 } p == 1" $PROFILECONF > $WORK
	fi

	# do not remove $PROFILE
	if [ "$REMOVE" = "no" ] ; then
		echo "[${PROFILE}]" >> $WORK
		for c in PROFILE \
			KUSANAGI_TYPE KUSANAGI_FQDN KUSANAGI_DIR \
			KUSANAGI_DBNAME KUSANAGI_DBUSER KUSANAGI_DBPASS \
			WPLANG OPT_WOO KUSANAGI_USER ; do
			if [[ -v $c ]]; then
				echo "$c=\"${!c}\"" >> $WORK
			fi
		done
	fi

	[ -d ${PROFILECONF%/*} ] || mkdir ${PROFILECONF%/*}
	cat $WORK > $PROFILECONF
	chmod 600 $PROFILECONF
	rm $WORK
}

function k_is_active() {
	# active=0, other=1
	[ -n "$1" ] && systemctl is-active $1.service 2> /dev/null | grep -w "active" > /dev/null ; echo $?
}

function k_is_enabled() {
	# enable=0, disabled=1
	[ -n "$1" ] && systemctl is-enabled $1.service 2> /dev/null | grep enabled > /dev/null ; echo $?
}

function k_status() {

	echo "Profile: $PROFILE"
	[[ -v KUSANAGI_TYPE ]] && echo Type: "$KUSANAGI_TYPE"
	cat /etc/kusanagi
	echo
	echo "*** nginx ***"
	systemctl status nginx | head -3
	echo
	#echo "*** Apache2 ***"
	#systemctl status httpd | head -3
	#echo
	#echo "*** HHVM ***"
	#systemctl status hhvm | head -3
	#echo
	#echo "*** php-fpm ***"
	#systemctl status php-fpm | head -3
	#echo
	echo "*** php7-fpm ***"
	systemctl status php7-fpm | head -3
    echo
	echo "*** ruby ***"
	if [ -f /usr/local/bin/ruby ]; then
	    /usr/local/bin/ruby --version
	else
	    echo 'KUSANAGI Ruby is not installed yet'
	fi
	echo
	echo "*** Cache Status ***"

	echo
	local RET=`grep -e "set[[:space:]]*\\$do_not_cache[[:space:]]*0[[:space:]]*;[[:space:]]*##[[:space:]]*page[[:space:]]*cache" $NGINX_HTTP`
	if [ "$RET" ]; then
		echo "fcache on"
	else
		echo "fcache off"
	fi
	if [ "$WPCONFIG" ]; then
		RET=`grep -e "^[[:space:]]*define[[:space:]]*([[:space:]]*'WP_CACHE'" $WPCONFIG | grep 'true'`
		if [ "$RET" ]; then
			echo "bcache on"
		else
			echo "bcache off"
		fi
	fi
}

function k_nginx() {
	echo $(eval_gettext "use nginx")
	if [ 0 -eq $(k_is_enabled httpd) ] ; then
		systemctl stop httpd && systemctl disable httpd
	fi
	systemctl restart nginx && systemctl enable nginx
	k_monit_reloadmonitor
}

function get_db_root_password() {
	if [ -e /root/.my.cnf ];then
		TMP=`grep password /root/.my.cnf | head -1`
		TMP=`echo $TMP | sed 's/^.*=\s*"//' | sed 's/"\s*$//'`
		echo $TMP
		TMP=""
	fi
}

function check_db_root_password() {
	local passwd=$1
	if [[ "$passwd" =~ ^[a-zA-Z0-9\.\!\#\%\+\_\-]{8,}$ ]]; then
		echo 0
	else
		echo 1
	fi
}
function set_db_root_password() {
	local oldpass=$1
	local newpass=$2
	TMP=`echo "show databases" | mysql -uroot -p"$oldpass" 2>&1 | grep information`
	# check password( Use [a-zA-Z0-9.!#%+_-] 8 characters minimum ).
	if [ "$TMP" = "" ] || [ 1 -eq $(check_db_root_password $newpass) ] ; then
		echo $(eval_gettext "Failed.")
		return 1
	fi
	echo "SET PASSWORD = PASSWORD('$newpass')" | mysql -uroot -p"$oldpass"
	sed -i "s/^\s*password\s*=.*$/password = \"$newpass\"/" /root/.my.cnf
	echo $(eval_gettext "Password has changed.")
}

function k_configure() {
	RET=`free -m | grep -e '^Mem:' | awk '{ print $2 }'`
	if [ "$RET" -gt 3600 ]; then
		INNODB_BUFFER=1536
		QUERY_CACHE=256
	elif [ "$RET" -gt 1800 ]; then
		INNODB_BUFFER=768
		QUERY_CACHE=192
	elif [ "$RET" -gt 900 ]; then
		INNODB_BUFFER=384
		QUERY_CACHE=128
	else
		INNODB_BUFFER=128
		QUERY_CACHE=64
	fi
	echo $(eval_gettext "innodb_buffer_pool_size = \${INNODB_BUFFER}M")
	echo $(eval_gettext "query_cache_size = \${QUERY_CACHE}M")
	sed -i "s/^\s*innodb_buffer_pool_size\s*=.*$/innodb_buffer_pool_size = ${INNODB_BUFFER}M/" /etc/my.cnf.d/server.cnf
	sed -i "s/^\s*query_cache_size\s*=.*$/query_cache_size = ${QUERY_CACHE}M/" /etc/my.cnf.d/server.cnf
	systemctl restart mysql
}

function k_ver_compare() {
	 /usr/bin/php -r '$a = version_compare( "'$1'", "'$2'", ">" ); if ( $a ) { exit( 1 ); } else { exit( 0 ); }'
}

function k_get_fqdn() {
	local PROFILE=$1
	local FQDN=
	if [[ -v KUSANAGI_FQDN ]] ; then
		FQDN=$KUSANAGI_FQDN
	elif [ ! -z $PROFILE ] && [ -f /etc/nginx/conf.d/${PROFILE}_http.conf ] ; then
		FQDN=$(awk -F'[ \t;]+' '/^[ \t]+server_name/ {printf "%s", $3}' /etc/nginx/conf.d/${PROFILE}_http.conf)
	fi
	echo $FQDN
}

function k_httpd() {
	echo $(eval_gettext "use TARGET") | sed "s|TARGET|$1|"
	if [ 0 -eq $(k_is_enabled nginx) ] ; then
		systemctl stop nginx && systemctl disable nginx
	fi
	systemctl restart httpd && systemctl enable httpd
	k_monit_reloadmonitor
}

#function k_phpfpm() {
#	echo $(eval_gettext "use TARGET") | sed "s|TARGET|$1|"
#	if [ 0 -eq $(k_is_enabled hhvm) ] ; then
#		systemctl stop hhvm && systemctl disable hhvm
#	fi
#	if [ 0 -eq $(k_is_enabled php7-fpm) ] ; then
#		systemctl stop php7-fpm && systemctl disable php7-fpm
#	fi
#	systemctl restart php-fpm && systemctl enable php-fpm
#}

function k_php7() {
	echo $(eval_gettext "use TARGET") | sed "s|TARGET|$1|"
	if [ 0 -eq $(k_is_enabled hhvm) ] ; then
		systemctl stop hhvm && systemctl disable hhvm
	fi
	if [ 0 -eq $(k_is_enabled php-fpm) ] ; then
		systemctl stop php-fpm && systemctl disable php-fpm
	fi
	systemctl restart php7-fpm && systemctl enable php7-fpm
}

#function k_hhvm() {
#	echo $(eval_gettext "use TARGET") | sed "s|TARGET|$1|"
#	if [ 0 -eq $(k_is_enabled php7-fpm) ] ; then
#		systemctl stop php7-fpm && systemctl disable php7-fpm
#	fi
#	if [ 0 -eq $(k_is_enabled php-fpm) ] ; then
#		systemctl stop php-fpm && systemctl disable php-fpm
#	fi
#	systemctl restart hhvm && systemctl enable hhvm
#}

####### configure switching among php versions
source /usr/lib/kusanagi/lib/sw-php.sh
function sw_latest_selected_php_proc() {
	# sw all provisions to the latest selected php version
	# $1 is user, $2 is desired php version
	bk_Passw0rd=`cat /usr/src/.bk_user_dwp`
	mysql -ubk_user -p$bk_Passw0rd \
    -e "select provision_name from kusanagi.provision where user_name = '$1' and deactive_flg = 0" | tail -n +2 |\
	while read prov; do
		if [ 0 -lt $(grep -E '^\s*fastcgi_pass\s+unix:\/var\/cache\/php-fpm\/' /etc/nginx/conf.d/${prov}_http.conf > /dev/null 2>&1; echo $?) ]; then
			sw_php $prov $2
		fi
	done
	if [ 0 -eq $(check_nginx_valid) ]; then
		systemctl reload nginx && systemctl enable nginx
	else
		echo "Nginx error. Please check"
	fi
}
function k_php_sw() {
	#input: php_version username
	local php_ver=$1
	local user_=$2
	if [ "$php_ver" != "php" ]; then
		for i in php7 php71 php72 php73 php74
		do
			if [ 0 -eq $(k_is_enabled ${i}-fpm.${user_}) ] || [ 0 -eq $(k_is_active ${i}-fpm.${user_}) ]; then
				systemctl stop ${i}-fpm.${user_} && systemctl disable ${i}-fpm.${user_}
			fi
		done
		if [ ! -d "/home/${user_}/log/php7" ]; then
			mkdir -p /home/${user_}/log/php7
			mkdir /home/${user_}/log/php7/session
			mkdir /home/${user_}/log/php7/wsdlcache
			chown -R ${user_}.${user_} /home/${user_}/log
		fi
		systemctl restart ${php_ver}-fpm.${user_} && systemctl enable ${php_ver}-fpm.${user_}
		sw_latest_selected_php_proc ${user_} ${php_ver}
	fi
}

######end


function k_ruby24() {
    echo $(eval_gettext "use TARGET") | sed "s|TARGET|$1|"
	local RUBY_VERSION="2.4"
	# Executable Ruby files
	local RUBY_EXECFILES=(ruby rdoc ri erb gem irb rake)
	for R_EXE in ${RUBY_EXECFILES[@]} ; do
	    if [ -L /usr/local/bin/${R_EXE} ]; then
	        unlink /usr/local/bin/${R_EXE}
	    fi
	    ln -s /bin/${R_EXE}${RUBY_VERSION} /usr/local/bin/${R_EXE}
	done
}

function k_ruby_init() {
    local rubyversion OPT_RUBY
	while :
    do
        echo $(eval_gettext "Then, Please tell me your ruby version.")
        echo $(eval_gettext "1) Ruby2.4")
        echo
        echo -n $(eval_gettext "Which you using?(1): ")
        read rubyversion
        case "$rubyversion" in
        ""|"1" )
             echo
             echo $(eval_gettext "You choose: Ruby2.4")
             OPT_RUBY=ruby24
             break
             ;;
        * )
             ;;
        esac
   done
   case "$OPT_RUBY" in
        'ruby24')
            kusanagi ruby24
            ;;
        *)
            ;;
   esac
}

function k_rails_init() {
    export RAILS_DB='mysql'
    if [ `yum repolist all | grep passenger | wc -l` -eq 0 ]; then
       curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo
    fi
    # depend on mod_passenger
    yum install -y mod_passenger
    yum install -y kusanagi-passenger
    yum install -y nodejs
    if [ ! -f /etc/httpd/modules/mod_passenger.so ]; then
       ln -s /usr/lib64/httpd/modules/mod_passenger.so /etc/httpd/modules/mod_passenger.so
    fi
    sed -i -e 's;/usr/lib64/httpd/modules/mod_passenger.so;modules/mod_passenger.so;' /etc/httpd/conf.modules.d/10-passenger.conf
    yum -y install libxml2 libxslt libxml2-devel libxslt-devel gmp-devel
}


function k_target() {
	if [ -z "${2}" ]; then
		echo $PROFILE
	elif [[ "$2" =~ ^[a-zA-Z0-9._-]{3,24}$ ]]; then
		PROFILE=$2
		k_read_profile $PROFILE dont
		#KUSANAGI_DIR="/home/kusanagi/$2"
		case $KUSANAGI_TYPE in
			"WordPress")
				# config file check
				[ -e $KUSANAGI_DIR/DocumentRoot/wp-config.php ] || [ -e $KUSANAGI_DIR/wp-config.php ] || return
				;;
			"concrete5")
				# config file check
				[ -e $KUSANAGI_DIR/DocumentRoot/application/config/database.php ] || return
				;;
			"drupal8")
				# config file is nothing
				[ -e $KUSANAGI_DIR/DocumentRoot/sites/default/settings.php ] || return
				;;
			"Rails")
	            # public directry check
	            [ -e $KUSANAGI_DIR/public ] || return
	            ;;
			"lamp")
				# config file is nothing
				[ -e $KUSANAGI_DIR/DocumentRoot ] || return
				;;
			*)
				return
		esac
		# change profile
		echo 'PROFILE="'$2'"' > /etc/kusanagi.conf
		echo $(eval_gettext "Target is changed to TARGET") | sed "s|TARGET|$2|"
			k_read_profile $PROFILE
	fi
}

function k_warmup() {

	local RET1=`grep 'server_name' $NGINX_HTTP | head -1 | sed 's/^\s*server_name\s*//' | sed 's/^.* //' | sed 's/\s*;\s*$//'`
	local RET2=`grep '^127.0.0.1 ' /etc/hosts | grep "$RET1"`
	if [ "$RET2" != "" ]; then
		if [ "$2" = "--extreme" ] && [ $(k_is_enabled hhvm)  -eq "0" ] ; then
			echo $(eval_gettext "Creating Byte Code. It takes a lot of time. Please wait.")
			echo $(eval_gettext "If this feauture doesn't works well, Try without '--extreme' option.")
			echo $(eval_gettext "And... If you change PHP files, Please run this command again.")
			/usr/bin/hhvm-repo-mode enable $KUSANAGI_DIR/DocumentRoot/
		else
			/usr/bin/hhvm-repo-mode disable
			echo -n "http://$RET1/  "
			for i in `seq 12`; do
				echo -n "#"
				curl "http://$RET1/" 1> /dev/null 2> /dev/null
			done
			echo
		fi
	fi
}


function k_update() {
	local ARGS=() YESFLAG= i=
	shift
	for i in "$@"
	do
		if [ "$i" = '-y' ] ; then
			YESFLAG=1
		else
			ARGS=("${ARGS[@]}" "$i")
		fi
	done

	case "${ARGS[0]}" in

	plugin)

		if [ -e $KUSANAGI_DIR/DocumentRoot/wp-content/mu-plugins/wp-kusanagi.php ] && \
			[ -e $KUSANAGI_DIR/DocumentRoot/wp-content/mu-plugins/kusanagi-wp-configure.php ]; then

			local MU_PLUGINS_DIR="$KUSANAGI_DIR/DocumentRoot/wp-content/mu-plugins"
			local RESOURCE_DIR="/usr/lib/kusanagi/resource/DocumentRoot/wp-content/mu-plugins"

			local CUR_PLUGIN_VER=`grep -e "Version: [0-9.]" $MU_PLUGINS_DIR/wp-kusanagi.php | sed -e "s/Version: \([0-9.]\)/\1/"`
			local LAT_PLUGIN_VER=`grep -e "Version: [0-9.]" $RESOURCE_DIR/wp-kusanagi.php | sed -e "s/Version: \([0-9.]\)/\1/"`
			local RET_PLUGIN=$(k_ver_compare $LAT_PLUGIN_VER $CUR_PLUGIN_VER; echo $?)

			local CUR_CONFIG_VER=`grep -e "Version: [0-9.]" $MU_PLUGINS_DIR/kusanagi-wp-configure.php | sed -e "s/Version: \([0-9.]\)/\1/"`
			local LAT_CONFIG_VER=`grep -e "Version: [0-9.]" $RESOURCE_DIR/kusanagi-wp-configure.php | sed -e "s/Version: \([0-9.]\)/\1/"`
			local RET_CONFIG=$(k_ver_compare $LAT_CONFIG_VER $CUR_CONFIG_VER; echo $?)

			if [ 1 -eq "$RET_PLUGIN" -o 1 -eq "$RET_CONFIG" ] && [ -z "$YESFLAG" ] ; then
				echo "Target: $PROFILE"
				echo -n $(eval_gettext "Upgrade ok?[y/N]: ")" "
				read is_upgrade
				case $is_upgrade in

				y)
					break
				;;
				*)
						echo $(eval_gettext "Abort.")
					exit 1
					break
				;;
				esac
			fi

			if [ 1 -eq "$RET_PLUGIN" ]; then
				echo $(eval_gettext "Update KUSANAGI plugin \$CUR_PLUGIN_VER to \$LAT_PLUGIN_VER")

				/bin/cp -f $RESOURCE_DIR/wp-kusanagi.php $MU_PLUGINS_DIR/wp-kusanagi.php
				chown kusanagi.kusanagi $MU_PLUGINS_DIR/wp-kusanagi.php
				/bin/cp -rpf $RESOURCE_DIR/kusanagi-core $MU_PLUGINS_DIR
				chown -R kusanagi.kusanagi $MU_PLUGINS_DIR/kusanagi-core
			else
				echo $(eval_gettext "KUSANAGI plugin is already latest version.")
			fi

			if [ 1 -eq "$RET_CONFIG" ]; then
				echo $(eval_gettext "Update KUSANAGI configure plugin \$CUR_CONFIG_VER to \$LAT_CONFIG_VER")

				/bin/cp -f $RESOURCE_DIR/kusanagi-wp-configure.php $MU_PLUGINS_DIR/kusanagi-wp-configure.php
				chown kusanagi.kusanagi $MU_PLUGINS_DIR/kusanagi-wp-configure.php
			else
				echo $(eval_gettext "KUSANAGI configure plugin is already latest version.")
			fi

		else
			echo $(eval_gettext "Plugin files not found. Noting to do.")
		fi

	;;
	cert)
		if [ -e $CERTBOT ]; then
			local CMD="$CERTBOT renew --quiet --renew-hook /usr/bin/ct-submit.sh "
			for i in nginx httpd
			do
				if [ 0 -eq $(k_is_enabled $i) ] ; then
					$CMD --post-hook "systemctl reload $i"
					k_monit_reloadmonitor
					return
				fi
			done
		fi
	;;
	*)
	break;;

	esac
}

function k_fcache() {
	case "${2}" in

	on)
		echo $(eval_gettext "Turning on")
		sed -i "s/set\s*\$do_not_cache\s*1\s*;\s*#\+\s*page\s*cache/set \$do_not_cache 0; ## page cache/" $NGINX_HTTP &&sed -i "s/set\s*\$do_not_cache\s*1\s*;\s*#\+\s*page\s*cache/set \$do_not_cache 0; ## page cache/" $NGINX_HTTPS
	;;
	off)
		echo $(eval_gettext "Turning off")
		sed -i "s/set\s*\$do_not_cache\s*0\s*;\s*#\+\s*page\s*cache/set \$do_not_cache 1; ## page cache/" $NGINX_HTTP
		sed -i "s/set\s*\$do_not_cache\s*0\s*;\s*#\+\s*page\s*cache/set \$do_not_cache 1; ## page cache/" $NGINX_HTTPS
	;;
	clear)
		if [ -d $NGINX_CACHE_DIR ]; then
			OWNER=`ls -dl $NGINX_CACHE_DIR | awk '{ print $3}'`
			NUM_DIR=`ls -dl $NGINX_CACHE_DIR | wc -l`
			if [ "$OWNER" = "kusanagi" ] && [ "$NUM_DIR" = "1" ]; then
				echo $(eval_gettext "Clearing cache")
				WP_CACHE_DIR=`grep -r "$KUSANAGI_FQDN" | cut -d " " -f3`
				rm -f $WP_CACHE_DIR
			fi
			return
		else
			echo $(eval_gettext "Nginx cache directory(\$NGINX_CACHE_DIR) is not found.")
			return 1
		fi
	;;
	*)
		local RET=`grep -e "set[[:space:]]*\\$do_not_cache[[:space:]]*0[[:space:]]*;[[:space:]]*##[[:space:]]*page[[:space:]]*cache" $NGINX_HTTP`
		if [ "$RET" ]; then
			echo $(eval_gettext "fcache is on")
		else
			echo $(eval_gettext "fcache is off")
		fi
		return
	;;
	esac
	# restart nginx when nginx is enabled
	if [ 0 -eq $(k_is_enabled nginx) ] ; then
		k_nginx
	else
		echo $(eval_gettext "Nginx is disable and nginx do not restart.")
		return 1
	fi
}


function k_bcache() {

	if [ -z "$WPCONFIG" ]; then
		echo $(eval_gettext "WordPress isn't installed. Nothing to do.")
		return
	fi
	case ${2} in

	on)
		if [ -e $WPCONFIG ]; then

			echo $(eval_gettext "Turning on")
			RET=`grep -i 'WP_CACHE' $WPCONFIG | wc -l`
			if [ "$RET" = "1" ]; then
				sed -i "s/^\s*define\s*(\s*'WP_CACHE'.*$/define('WP_CACHE', true);/" $WPCONFIG
				sed -i "s/^\s*[#\/]\+\s*define\s*(\s*'WP_CACHE'.*$/define('WP_CACHE', true);/" $WPCONFIG
			else
				CHECK=`cat $WPCONFIG | grep "WP_CACHE" > /dev/null; echo $?`
				if [ $CHECK -eq 0 ]; then
				exit 1
				fi
				sed -i "/define('WP_DEBUG', false);/a\define('WP_CACHE', true);" $WPCONFIG
				#echo $(eval_gettext "Failed. Constant WP_CACHE defined multiple.")
			fi

		fi
	;;
	off)
		if [ -e $WPCONFIG ]; then
			echo $(eval_gettext "Turning off")
			local RET=`grep -i 'WP_CACHE' $WPCONFIG | wc -l`
			if [ "$RET" = "1" ]; then
				sed -i "s/^\s*define\s*(\s*'WP_CACHE'.*$/#define('WP_CACHE', true);/" $WPCONFIG
			else
				echo $(eval_gettext "Failed. Constant WP_CACHE defined multiple.")
			fi
		fi
	;;
	clear)
		echo $(eval_gettext "Clearing cache")
		cd $TARGET_DIR/tools
		php ./bcache.clear.php
	;;
	*)
		local RET=`grep -e "^[[:space:]]*define[[:space:]]*([[:space:]]*'WP_CACHE'" $WPCONFIG | grep 'true'`
		if [ "$RET" ]; then
			echo $(eval_gettext "bcache is on")
		else
			echo $(eval_gettext "bcache is off")
		fi
	;;
	esac
}

function k_zabbix() {
	case ${2} in
	on)
		echo $(eval_gettext "Try to start zabbix-agent")
		systemctl restart zabbix-agent &&systemctl enable zabbix-agent &&systemctl status zabbix-agent | head -3
	;;
	off)
		echo $(eval_gettext "Try to stop zabbix-agent")
		systemctl stop zabbix-agent &&systemctl disable zabbix-agent &&systemctl status zabbix-agent | head -3
	;;
	*)
		if [ 0 -eq $(k_is_active zabbix-agent) ] ; then
			echo $(eval_gettext "zabbix is on")
		else
			echo $(eval_gettext "zabbix is off")
		fi
	;;
	esac
}

function k_restart() {
	local _RET=0
	for service in $@ ; do
		if [ 0 -eq $(k_is_enabled $service) ] ; then
			systemctl restart $service
			_RET=$?
		else
			:
		fi
	done
	return $_RET
}

function k_reload() {
	local _RET=0
	for service in $@ ; do
		if [ 0 -eq $(k_is_enabled $service) ] ; then
			systemctl reload $service
			_RET=$?
		else
			:
		fi
	done
	return $_RET
}

function k_monit_reloadmonitor() {
	if [ 0 -ne $(k_is_enabled monit) ] ; then
		:
	elif [ 0 -eq $(k_is_enabled nginx) ]; then
		monit -g httpd unmonitor all
		monit -g nginx monitor all
	elif [ 0 -eq $(k_is_enabled httpd) ]; then
		monit -g nginx unmonitor all
		monit -g httpd monitor all
	fi
}

function k_monit() {
	local ENABLE_MONIT=$(k_is_enabled monit)
	local opt="${2,,}"
	if [ "$opt" = "on" ]; then	# comparison in lowercase.
		# start monit if monit is down.
		if [ 1 -eq $ENABLE_MONIT ]; then
			systemctl start monit && systemctl enable monit
			if [ $? -eq 0 ]; then
				echo $(eval_gettext "monit on")
				k_monit_reloadmonitor
			else
				echo $(eval_gettext "monit cannot be on")
				return 1
			fi
		else
			echo $(eval_gettext "monit is already on. Nothing to do.")
		fi
	elif [ "$opt" = "off" ]; then
		# stop monit if monit is updown.
		if [ 0 -eq $ENABLE_MONIT ]; then
			monit -g httpd unmonitor all
			monit -g nginx unmonitor all
			systemctl stop monit && systemctl disable monit && \
			echo $(eval_gettext "monit off") || echo $(eval_gettext "monit cannot be off")
		else
			echo $(eval_gettext "monit is already off. Nothing to do.")
		fi
	elif [ "$opt" = "config" ]; then
		k_read_profile ${3:-$PROFILE}
		for ITEM in "etc/monit.d/fqdn_httpd.conf" "etc/monit.d/fqdn_nginx.conf"; do
			local TARGET="/"`echo $ITEM | sed "s/fqdn/$PROFILE/"`
			local SOURCE="/usr/lib/kusanagi/resource/$ITEM"
			local BACKUPDIR="/etc/monit.d/backup"
			if [ -f $TARGET ]; then 	# backup old configure file
				if [ \! -d $BACKUPDIR ] ; then
					mkdir -p $BACKUPDIR
				fi
				# ex. 2016-05-16_12:31:55
				local DATESTR=$(stat -c '%y' $TARGET | awk -F. '{print $1}'|sed 's/ /_/')
				mv ${TARGET} ${BACKUPDIR}/${TARGET##*/}.${DATESTR}
			fi
			cat $SOURCE | sed "s/profile/$PROFILE/g" > $TARGET
		done
	elif [ "$opt" = "reload" ] ; then
		echo $(eval_gettext "monit is reloaded.")
		systemctl reload monit
		if [ $? -eq 0 ] ; then
			sleep 1
			k_monit_reloadmonitor
		else
			echo $(eval_gettext "monit cannot reload")
			return 1
		fi
	else
		if [ 0 -eq $(k_is_active monit) ]; then
			echo $(eval_gettext "monit is on")
		else
			echo $(eval_gettext "monit is off")
		fi
	fi
}

function is_root_domain() {
	#USING: init,ssl option. DON'T REMOVE THIS. THIS CODE USING AND CLEANING CODE.
	#Arg: domain
	local domain=$1
	local APEX=
	echo $domain | grep "^www\." >/dev/null 2>&1
	if [ "$?" -eq 0 ] ; then
		APEX=`echo $domain | cut -c 5-` #<<<<<<< BREAK POINT >>>>>>>
		dig $APEX a | grep ".*IN.*[^SO]A.*[0-9.]\{7,15\}" >/dev/null 2>&1
		if [ "$?" -eq 1 ] ; then
			return 2
		else
			WITH_WWW=0
		fi
	else
		dig www.$domain a | grep ".*IN.*[^SO]A.*[0-9.]\{7,15\}" >/dev/null 2>&1
		if [ "$?" -eq 1 ] ; then
			return 2
		else
			APEX="$domain"
			WITH_WWW=1
		fi
	fi
	whois $APEX | grep "^NOT FOUND\|^No match" >/dev/null 2>&1
	if [ "$?" -eq 1 ] ; then
		# Apex Domain.
		if [ "$WITH_WWW" -eq 1 ] ; then
			# Pure Apex Domain.
			return 0
		else
			#With www but Remove, Apex Domain.
			return 1
		fi
	else
		# Non-Apex Domain
		return 2
	fi
}

function shrink_str() {
	local LINE=
	local CHAR=
	local s=0

	read LINE && echo $LINE
	read LINE && echo $LINE
	while read -s -N 1 CHAR
	do 
		if [ "." =  "$CHAR" ] || [ "+" = "$CHAR" ] ; then
			s=$((s+1))
			if [ 0 -eq $(($s % 10)) ] ; then
				echo -n $CHAR 
			fi
		fi
	done
}

function k_generate_seckey() {
	local shrink=${1:-}
	if [ ! -d /etc/kusanagi.d/ssl ] ; then
		mkdir -p /etc/kusanagi.d/ssl
	fi
	if [ ! -e /etc/kusanagi.d/ssl/ssl_sess_ticket.key ] ; then
		openssl rand 48 > /etc/kusanagi.d/ssl_sess_ticket.key
	fi
	if [ ! -e /etc/kusanagi.d/ssl/dhparam.key ] ; then
		echo $(eval_gettext "Generating 2048bit DHE key for security") 1>&2
		if [ -n "$shrink" ] ; then
			openssl dhparam 2048 -out /etc/kusanagi.d/ssl/dhparam.key 2>&1 | shrink_str
		else
			openssl dhparam 2048 -out /etc/kusanagi.d/ssl/dhparam.key
		fi
		echo $(eval_gettext "Finish.") 1>&2
	fi
}
