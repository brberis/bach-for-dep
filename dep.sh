#!/bin/sh

usage="$(basename "$0") [-h] [-d] [-ssl] [-g] [-s] [-f] [-v] [-t] [-e] [-b] [-r] [-m] [-y] [-a] [-c] [-q <string> ] [-k <string> ] [-l <email> ] <[-z <db password> ] [--git_url <string> --project_name <string> --port <number> --domain <srtring> --server_ip <string>] -- Vexweb program to deploy new project.

where:
	-h | --help			Show this help text
	-o | --git_url  		Enter git url 
	-n | --project_name  		Set the new project name
	-d | --detele_migrations 	Delete all migrations files
	-p | --port 			Set gunicorn port project
	-i | --ip 			Server ip
	-w | --domain 			Project domain without www
	-x | --ssl 			Set project ssl
	-g | --nginx 			Set a config file in availables and enabled folder
	-f | --rename_strings 		Rename old template string to new one
	-v | --virtual_enviroment 	Create virtual enviroment for the project
	-t | --clone_git 		Create a git clone from git utl
	-s | --supervisor 		Set project in supervisor config file
	-e | --delete_supervisor 	Delete project in supervisor config file
	-b | --create_database 		Create a database for the project
	-r | --install_requirements 	Install Python requirements for this project
	-m | --migrate 	Migrate Django project for first time
	-y | --fix_directories 		Fix user:group and mod for this project
	-z | --terminate 		Terminate project (Need to provide DB password)
	-a | --test_mode 		Create project in test mode
	-c | --create_superuser 		Create Django superuser
	-q | --superuser_user 		Username for superuser
	-k | --superuser_password 		Password for superuser
	-l | --superuser_email 		Email for superuser



important:
	Run this script from root projects folder (/home/projects/).
	(port range 95xx)

"

OPTIONS=$(getopt -o ho:n:dfp:w:xgsevtbrmyz:ai:cq:k:l: -l help,git_url:,project_name:,delete_migrations,rename_strings,port:,domain:,ssl,nginx,supervisor,delete_supervisor,virtual_enviroment,CLONE_GIT,install_requirements,create_database,migrate,fix_directories,terminate:,test_mode,create_superuser,superuser_user:,superuser_password:,superuser_email:,server_ip: -- "$@")

if [[ $# -eq 0 ]]; then
	echo "$usage"
	exit 1
else
	eval set -- $OPTIONS
	while true; do
		case "$1" in
		-h|--help) HELP=1 ;;
		-o|--GIT_URL) GIT_URL="$2" ; shift ;;
		-n|--project_name) PROJECT_NAME="$2" ; shift ;;
		-p|--port) PORT="$2" ; shift ;;
		-w|--domain) DOMAIN="$2" ; shift ;;
		-i|--server_ip) SERVER_IP="$2" ; shift ;;
		-d|--delete_migrations)  DM=1 ;;
		-f|--rename_strings)  RENAME_STRINGS=1 ;;
		-x|--ssl)  SSL=1 ;;
		-g|--nginx)  NGINX=1 ;;
		-s|--supervisor)  SUPERVISOR=1 ;;
		-e|--delete_supervisor)  DELETE_SUPERVISOR=1 ;;
		-v|--virtual_enviroment)  VIRTUAL_ENVIROMENT=1 ;;
		-t|--clone_git)  CLONE_GIT=1 ;;
		-b|--create_database)  CREATE_DATABASE=1 ;;
		-r|--install_requirements)  INSTALL_REQUIREMENTS=1 ;;
		-m|--migrate)  MIGRATE=1 ;;
		-y|--fix_directories)  FIX_DIRECTORIES=1 ;;
		-z|--terminate) TERMINATE="$2" ; shift ;;
		-a|--test_mode)  TEST_MODE=1 ;;
		-c|--create_superuser)  CREATE_SUPERUSER=1 ;;
		-q|--superuser_user) SUPERUSER_USER="$2" ; shift ;;
		-k|--superuser_password) SUPERUSER_PASSWORD="$2" ; shift ;;
		-l|--superuser_email) SUPERUSER_EMAIL="$2" ; shift ;;
		--)        shift ; break ;;
		*)         echo "unknown option: $1" ; exit 1 ;;
	esac
	shift
  	done

  if [ $# -ne 0 ]; then
	echo "unknown option(s): $@"
	exit 1
  fi

  if [[ $HELP == 1 ]]; then
	echo "$usage"
	exit 1
  fi

  if [[ $VIRTUAL_ENVIROMENT == 1 ]]; then
	  if [[ -z "$PROJECT_NAME" ]]; then
	    echo "$usage"
	    exit 1
	  else
		  echo "creating new enviroment..."
		  virtualenv -p python3 /home/projects/clients/$PROJECT_NAME
		  echo "done!"
  	fi
  fi
  if [[ $VIRTUAL_ENVIROMENT == 1 ]]; then
  	if [[ -z "$PROJECT_NAME" ]]; then
    	echo "$usage"
    	exit 1
  	else
		  echo "activating enviroment..."
		  source /home/projects/clients/$PROJECT_NAME/bin/activate
		  echo "done!"
		fi
  fi
  if [[ $CLONE_GIT == 1 ]]; then
  	if [[ -z "$GIT_URL" ]] && [[ -z "$PROJECT_NAME" ]]; then
		  echo "$usage"
	    exit 1
	  else
		  echo "cloning git..."
		  git clone --recurse $GIT_URL /home/projects/clients/$PROJECT_NAME/src
		  cd /home/projects/clients/$PROJECT_NAME/src
		  git rm --cached settings/settings.py
		  git rm --cached settings/urls.py
		  git rm --cached manage.py
		  git rm --cached media
		  git rm --cached static
		  git rm --cached .DS_Store
		  git add .gitignore
		  git commit -m "gitignore added"
		  mkdir /home/projects/clients/$PROJECT_NAME/src/media
		  ln -s /home/projects/clients/$PROJECT_NAME/src/media /home/projects/clients/$PROJECT_NAME/src/settings/media
		  ln -s /home/projects/clients/$PROJECT_NAME/src/static /home/projects/clients/$PROJECT_NAME/src/settings/static
		  echo "done!"
		fi
  # 	if [[ -z "$GIT_URL" ]]; then
		#   echo "$usage"
	 #    exit 1
	 #  else
	 #  	mkdir $PROJECT_NAME
		#   echo "deploying files from template..."
		#   cp -r /home/projects/castorgc/src /home/projects/clients/$PROJECT_NAME/.
		#   ln -s /home/projects/clients/$PROJECT_NAME/src/media /home/projects/clients/$PROJECT_NAME/src/%PROJECT_NAME/media
		#   ln -s /home/projects/clients/$PROJECT_NAME/src/static /home/projects/clients/$PROJECT_NAME/src/%PROJECT_NAME/static
		#   echo "done!"
		# fi
  fi

  if [[ $DM == 1 ]]; then
  	if [[ -z "$PROJECT_NAME" ]]; then
	    echo "$usage"
	    exit 1
  	else
			echo "deleting migrations..."
			shopt -s globstar
			rm -rf /home/projects/clients/$PROJECT_NAME/src/**/*migrations*/00*
			rm -rf /home/projects/clients/$PROJECT_NAME/src/**/*migrations*/__pycache*
			echo "done!"
			echo "deleting cache..."
			rm -rf /home/projects/clients/$PROJECT_NAME/src/**/__pycache*
			rm -rf /home/projects/clients/$PROJECT_NAME/src/**/*.pyc
			echo "done!"		
		fi
  fi
	if [[ $RENAME_STRINGS == 1 ]]; then
			# echo "renaming folders..."
			# find $PROJECT_NAME/src/. -type d -name $GIT_URL -exec prename "s/$GIT_URL/$PROJECT_NAME/" {} \;
			# echo "done!"
			echo "renaming strings on files..."
			( shopt -s globstar dotglob;
			   for file in /home/projects/clients/$PROJECT_NAME/src/**; do
				   if [[ -f $file ]] && [[ -w $file ]]; then
					   sed -i -- "s/vex_base_template/$PROJECT_NAME/g" "$file"
				   fi
			   done
			)
			echo "done!"
			echo "setting new key in settings.py"
			KEY="$(openssl rand -base64 45)"
			KEY=$(sed 's/[^a-zA-Z0-9]/\\&/g' <<<"$KEY")
			settings_file="/home/projects/clients/$PROJECT_NAME/src/settings/settings.py"
			sed  -i -- "s/<VEX-SECRET-KEY>/$KEY/" $settings_file		
	fi
	if [[ $PORT > 0 ]]; then
		if [[ -z "$PROJECT_NAME" ]]; then
		echo "$usage"
		exit 1
		else
	  	echo "creating gunicorn.sh file..."
		cat <<- EOF > /home/projects/clients/$PROJECT_NAME/gunicorn.sh
		#!/bin/bash
		source /home/projects/clients/$PROJECT_NAME/bin/activate
		cd /home/projects/clients/$PROJECT_NAME/src
		exec /home/projects/clients/$PROJECT_NAME/bin/gunicorn settings.wsgi:application  --bind=127.0.0.1:$PORT
		EOF
			chmod +x /home/projects/clients/$PROJECT_NAME/gunicorn.sh
	  	echo "done!"
	  fi
	fi
  
  if [[ $INSTALL_REQUIREMENTS == 1 ]]; then
  	if [[ -z "$PROJECT_NAME" ]]; then
			echo "$usage"
			exit 1
	  elif source /home/projects/clients/$PROJECT_NAME/bin/activate; then
	  	echo "activating enviroment..."
			echo "done!"
			echo "installing python requirement packages..."
			pip install -U pip
			pip install -r /home/projects/clients/$PROJECT_NAME/src/vexreq.txt
			echo "done!"
		else
			echo "Please create enviroment first"
	  fi
	fi

  if [[ $CREATE_DATABASE == 1 ]]; then
  	if [[ -z "$PROJECT_NAME" ]]; then
  		echo "$usage"
		  exit 1
  	else
		DBCHECK=`mysqlshow $PROJECT_NAME| grep -v Wildcard | grep -o $PROJECT_NAME`
			if [ "$DBCHECK" == "$PROJECT_NAME" ]; then
			    echo "Database already exist!"
			else
				echo "creating database..."
				# create random password
				if [[ $TEST_MODE == 1 ]]; then
					PASSWDDB="test_password"
				else
					PASSWDDB="$(openssl rand -base64 12)"
					PASSWDDB=$(sed 's/[^a-zA-Z0-9]/\\&/g' <<<"$PASSWDDB")
				fi

				# replace "-" with "_" for database username
				USER_TEXT="u"
				MAINDB=$PROJECT_NAME
				USERDB=$PROJECT_NAME$USER_TEXT

				# If /root/.my.cnf exists then it won't ask for root password
				if [ -f /root/.my.cnf ]; then

				    mysql -e "CREATE DATABASE $MAINDB /*\!40100 DEFAULT CHARACTER SET utf8 */;"
				    mysql -e "CREATE USER $USERDB@localhost IDENTIFIED BY '$PASSWDDB';"
				    mysql -e "GRANT ALL PRIVILEGES ON $MAINDB.* TO '$USERDB'@'localhost';"
				    mysql -e "FLUSH PRIVILEGES;"

				fi	
				echo "done!"
				echo "adding configuration in settings.py"

				settings_file="/home/projects/clients/$PROJECT_NAME/src/settings/settings.py"
				sed  -i -- "s/<VEX-DATABASE-NAME>/$MAINDB/" $settings_file
				sed  -i -- "s/<VEX-DATABASE-USER>/$USERDB/" $settings_file
				sed  -i -- "s/<VEX-DATABASE-PASSWORD>/$PASSWDDB/" $settings_file
				echo "done!"			
			fi
		fi
	fi	

  if [[ $NGINX == 1 ]]; then	
  	if [[ -z "$PROJECT_NAME" ]] || [[ -z "$SERVER_IP" ]] || [[ -z "$PORT" ]] || [[ -z "$DOMAIN" ]]; then
   		echo "$usage"
			exit 1
  	else
			APP_SERVER='_app_server'
			UPSTREAM=$PROJECT_NAME$APP_SERVER
			if [[ -z "$SSL" ]]; then
		  	echo "setting nginx configuration without SSL"
			cat <<- EOF > /etc/nginx/sites-available/$DOMAIN 
			upstream $UPSTREAM {
			    server 127.0.0.1:$PORT fail_timeout=0;
			}
			server {
			    listen $SERVER_IP:80;
			    listen [::]:80;

			    root /usr/share/nginx/html;
			    index index.html index.htm;
			    client_max_body_size 4G;
			    server_name $DOMAIN www.$DOMAIN;
			    keepalive_timeout 5;

			    # Your Django project's media files - amend as required
			    location /media  {
			        alias /home/projects/clients/$PROJECT_NAME/src/media;
			    }
			    # your Django project's static files - amend as required
			    location /static {
			        alias /home/projects/clients/$PROJECT_NAME/src/static; 
			    }
			    # Proxy the static assests for the Django Admin panel
			    location /static/admin {
			        alias /home/projects/clients/$PROJECT_NAME/src/static/admin;
			    }
			    location / {
			        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
			        proxy_set_header Host \$http_host;
			        proxy_redirect off;
			        proxy_pass http://$UPSTREAM;
			    }
			}
			EOF
			else
		  	echo "setting nginx configuration with SSL"
		  	CHAINED="_chained.pem"
			cat <<- EOF > /etc/nginx/sites-available/$DOMAIN 
			upstream $UPSTREAM {
			server 127.0.0.1:$PORT fail_timeout=0;
			}
			server {
			    listen $SERVER_IP:80;
			    listen [::]:80;
			    server_name $DOMAIN www.$DOMAIN;
			    return         301 https://\$server_name\$request_uri;
			}

			server {
			    listen 443 ssl;
			    server_name $DOMAIN www.$DOMAIN;
			    ssl on;


			    root /usr/share/nginx/html;
			    index index.html index.htm;

			    client_max_body_size 4G;
			    ssl_certificate /etc/ssl/certs/$PROJECT_NAME$CHAINED;
			    ssl_certificate_key /etc/ssl/private/$PROJECT_NAME.key;
			    ssl_dhparam /etc/ssl/certs/dhparam.pem;


			    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
			    ssl_prefer_server_ciphers on;
			    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
			    ssl_session_cache shared:SSL:10m;


			    keepalive_timeout 5;

			    # Your Django project's media files - amend as required
			    location /media  {
			        alias /home/projects/clients/$PROJECT_NAME/src/media;
			    }

			    # your Django project's static files - amend as required
			    location /static {
			        alias /home/projects/clients/$PROJECT_NAME/src/static;
			    }


			    # Proxy the static assests for the Django Admin panel
			    location /static/admin {
			       alias /home/projects/clients/$PROJECT_NAME/src/static/admin/;
			    }

			    location / {
			        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
			        proxy_set_header Host \$http_host;
			        proxy_redirect http:// https://;
			        proxy_http_version 1.1;
			        proxy_set_header Upgrade \$http_upgrade;
			        proxy_pass http://$UPSTREAM;
			        
			       if (\$request_method = 'OPTIONS') {

			         add_header 'Access-Control-Allow-Origin' 'https://reservation.exchange';
			                
			        #
			        # Om nom nom cookies
			        #    
			         add_header 'Access-Control-Allow-Credentials' 'true';
			         add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
			        # add_header 'Access-Control-Expose-Headers' 'Authorization';
			            
			        #
			        # Custom headers and headers various browsers *should* be OK with but aren't
			        #

			        add_header 'Access-Control-Allow-Headers' 'Authorization,DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
			            
			        #
			        # Tell client that this pre-flight info is valid for 20 days
			        #

			        add_header 'Access-Control-Max-Age' 1728000;
			        add_header 'Content-Type' 'text/plain charset=UTF-8';
			        add_header 'Content-Length' 0;

			        return 204;
			        }

			       if (\$request_method = 'POST') {

			        add_header 'Access-Control-Allow-Origin' 'https://reservation.exchange';
			        add_header 'Access-Control-Allow-Credentials' 'true';
			        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
			        add_header 'Access-Control-Allow-Headers' 'Authorization,DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
			        # add_header 'Access-Control-Expose-Headers' 'Authorization';
			      }

			      if (\$request_method = 'GET') {

			        add_header 'Access-Control-Allow-Origin' 'https://reservation.exchange';
			        add_header 'Access-Control-Allow-Credentials' 'true';
			        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
			        add_header 'Access-Control-Allow-Headers' 'Authorization,authorization,client-security-token,DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
			        # add_header 'Access-Control-Expose-Headers' 'Authorization';
			      }

			}
			}
			EOF
			fi
			if [ -f /etc/nginx/sites-available/$DOMAIN ]; then
				ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled
						service nginx restart
			else
				echo "ERROR: nginx couldn't be created"
				exit 1
			fi
			echo "done!"
  	fi
  fi
  if [[ $MIGRATE == 1 ]]; then	
  	if [[ -z "$PROJECT_NAME" ]]; then
   		echo "$usage"
			exit 1
  	else
  		echo "activating enviroment..."
		  source /home/projects/clients/$PROJECT_NAME/bin/activate
		  echo "done!"
  		echo "migrating"
  		python /home/projects/clients/$PROJECT_NAME/src/manage.py migrate
  		python /home/projects/clients/$PROJECT_NAME/src/manage.py makemigrations
  		python /home/projects/clients/$PROJECT_NAME/src/manage.py migrate
  		echo "done"
  		echo "collecting static"
  		python /home/projects/clients/$PROJECT_NAME/src/manage.py collectstatic --noinput
  		echo "done"
  	fi
  fi

  if [[ $FIX_DIRECTORIES == 1 ]]; then
  	if [[ -z "$PROJECT_NAME" ]]; then
   	  echo "$usage"
	  	exit 1
  	else
			echo "fixing directories..."
			chown -R brberis:brberis /home/projects/clients/$PROJECT_NAME
			chmod -R 775 /home/projects/clients/$PROJECT_NAME/src/media
			echo "done!"
  	fi
  fi

  if [[ $SUPERVISOR == 1 ]] || [[ $DELETE_SUPERVISOR == 1 ]]; then
  	if [[ -z "$PROJECT_NAME" ]]; then
   	  echo "$usage"
	  	exit 1
  	else
	  	echo "updating supervisor configuration..."
			conf_file="/etc/supervisor/conf.d/long_script.conf"
			if grep -qF "[program:$PROJECT_NAME]" $conf_file; then
				sed  -i -- "/program:$PROJECT_NAME/,/stdout_logfile/d" $conf_file
				supervisorctl reread
				supervisorctl update
			fi
		fi
	fi
	if [[ $SUPERVISOR == 1 ]]; then
  	if [[ -z "$PROJECT_NAME" ]]; then
   	  echo "$usage"
	  	exit 1
  	else
cat >>$conf_file <<EOF

[program:$PROJECT_NAME]
command=/home/projects/clients/$PROJECT_NAME/gunicorn.sh
autostart=true
autorestart=true
stderr_logfile=/var/log/$PROJECT_NAME.err.log
stdout_logfile=/var/log/$PROJECT_NAME.out.log
EOF

supervisorctl reread
supervisorctl update
supervisorctl start $PROJECT_NAME 

		fi
	echo "done!"
  fi

  if [[ $TERMINATE ]]; then
  	if [[ -z "$PROJECT_NAME" ]] || [[ -z "$DOMAIN" ]]; then
  		echo "$usage"
		  exit 1
  	else
  		if [[ -d /home/projects/clients/$PROJECT_NAME ]]; then
  			settings_file="/home/projects/clients/$PROJECT_NAME/src/settings/settings.py"
  			dbpass=$(grep -Po "'PASSWORD': '\K.*?(?=',)" $settings_file)
  	 		if [[ $dbpass == $TERMINATE ]]; then
  				echo "Deleting files..."
  				rm -r /home/projects/clients/$PROJECT_NAME
  				echo "done!"
  				echo "Deleting from supervisor..." 
					conf_file="/etc/supervisor/conf.d/long_script.conf"
					if grep -qF "[program:$PROJECT_NAME]" $conf_file; then
						sed  -i -- "/program:$PROJECT_NAME/,/stdout_logfile/d" $conf_file
						supervisorctl reread
						supervisorctl update
					fi
					echo "done!"
					echo "Deleting from NGINX..."
					if [ -f /etc/nginx/sites-enabled/$DOMAIN ]; then
						rm /etc/nginx/sites-enabled/$DOMAIN
						service nginx restart
					fi
					if [ -f /etc/nginx/sites-available/$DOMAIN ]; then
						rm /etc/nginx/sites-available/$DOMAIN
					fi

					echo "done!"
					echo "Deleting Database..."
					if [ -f /root/.my.cnf ]; then
						  USER_TEXT="u"
							USERDB=$PROJECT_NAME$USER_TEXT
					    mysql -e "DROP DATABASE IF EXISTS $PROJECT_NAME;"
				      mysql -e "FLUSH PRIVILEGES;"
					    mysql -e "DROP USER '$USERDB'@'localhost';"
					    mysql -e "FLUSH PRIVILEGES;"
					   	echo "done!"
					else
						echo "No db password finded"
					fi	
					echo "Deleting logs..."
					if [ -f /var/log/$PROJECT_NAME.err.log ]; then
						rm /var/log/$PROJECT_NAME.err.log
					fi
					if [ -f /var/log/$PROJECT_NAME.out.log ]; then
						rm /var/log/$PROJECT_NAME.out.log
					fi
					echo "done!"
			  else
  				echo "Can't terminate project. Wrong password."
  			fi
  		else
  			echo "Project don't exist."
  		fi
  	fi
  fi
  if [[ $CREATE_SUPERUSER == 1 ]]; then
  	if [[ -z "$PROJECT_NAME" ]] || [[ -z "$SUPERUSER_USER" ]] || [[ -z "$SUPERUSER_PASSWORD" ]] || [[ -z "$SUPERUSER_EMAIL" ]]; then
  		echo "$usage"
		  exit 1
  	elif source /home/projects/clients/$PROJECT_NAME/bin/activate; then
  		python /home/projects/clients/$PROJECT_NAME/src/manage.py shell -c "from django.contrib.auth.models import User; User.objects.create_superuser('$SUPERUSER_USER', '$SUPERUSER_EMAIL', '$SUPERUSER_PASSWORD')"
  		echo "done!"
  	fi
  fi



fi
