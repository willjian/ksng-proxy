cd /home/$CUSTOM_USER

/usr/local/bin/gem install rails
/bin/rails new $PROFILE -d ${RAILS_DB}

RAILS_BASE_DIR=/home/$CUSTOM_USER/$PROFILE

chown -R $CUSTOM_USER $RAILS_BASE_DIR
chgrp -R $CUSTOM_USER $RAILS_BASE_DIR

servers=(nginx httpd)
for server in ${servers[@]}; do
	echo 
	if [ ! -d ${RAILS_BASE_DIR}/log/${server} ]; then
		mkdir -p ${RAILS_BASE_DIR}/log/${server}
	fi
done

writable_dirs=(log tmp)
for dir in ${writable_dirs[@]}; do
	chown -R $CUSTOM_USER.kusanagi ${RAILS_BASE_DIR}/${dir}
	chmod -R g+w ${RAILS_BASE_DIR}/${dir}
done

