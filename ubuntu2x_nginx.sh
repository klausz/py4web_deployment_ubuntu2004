#!/bin/bash
#

# ========================================================================
#   machine-setup.sh
#
# installation script for Nginx on Ubuntu Server
#   tested with Ubuntu Server 20.04.03 LTS
#
# Usage:
#       copy and run it in any directory with 'sudo ./machine-setup.sh'
#       
# ========================================================================

#Manuell
#sudo adduser klaus
#adduser klaus sudo #ist er damit auch schon hinzugefügt?
#logout
#login klaus



echo "======================================="
echo "Installing Packages"
echo "======================================="

sudo apt-get update
sudo apt-get upgrade
sudo apt install nginx


#sudo ufw app list
#sudo ufw allow 'Nginx HTTP'
#sudo ufw status #ist leider inaktiv
#sudo systemctl status nginx #running scheint ok
#sudo systemctl start nginx
#sudo systemctl stop nginx
#sudo systemctl restart nginx
#sudo systemctl reload nginx #after changed in settings etc
#sudo mkdir -p /var/www/example1.com
#ls /var/www #to see if it is there 
#sudo chown -R $USER:$USER /var/www/example1.com #muss doppelpunkt nicht strichpunkt sein
#sudo chmod 750 /var/www/example1.com
#sudo chown -R www-data /var/www/example1.com
#sudo vim /var/www/example1.com/html/index.html
#<!DOCTYPE html>
#<html lang="en">
#<head>
#    <meta charset="UTF-8">
#    <meta name="viewport" content="width=device-width, initial-scale=1.0">
#    <title>Welcome to example1.com!</title>
#</head>
#<body>
#    <header>
#        <h1>Example1.com</h1>
#    </header>
#    <main>
#        <p>Congratulations! You've successfully reached the example1.com
#server.</p>
#    </main>
#    <footer>
#        <p>Thank you for visiting example1.com!</p>
#    </footer>
#</body>
#</html>
#save as index.html #achtung: ich konnte es nicht ins Zielverzeichnis 
#sudo vim /etc/nginx/sites-available/example1.com
#server {
#    listen 80;
#    listen [::]:80;
#    root /var/www/example1.com/html;
#    index index.html index.htm index.nginx-debian.html;
#    server_name example1.com www.example1.com;
#    location / {
#        try_files $uri $uri/ =404;
#} }
#obiges konnte ich schreiben
#sudo ln -s /etc/nginx/sites-available/example1.com /etc/nginx/sites-enabled/
#sudo unlink /etc/nginx/sites-enabled/default
#sudo nginx -t #Problem



if [ ! -d /etc/nginx/sites-available/py4web ]
then
    echo "======================================="
    echo "configuring NGINX"
    echo "======================================="
    mkdir -p /etc/nginx/conf.d/py4web
# Create configuration file /etc/nginx/sites-available/py4web
echo 'server {
        listen          80;
        server_name     $hostname;
        location ~* ^/(\w+)/static(?:/_[\d]+\.[\d]+\.[\d]+)?/(.*)$ {
            alias /home/www-data/py4web/apps/$1/static/$2;
            expires max;
        }
        location / {
            proxy_set_header   X-Forwarded-Proto $scheme;
            proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header   Host $http_host;
            proxy_set_header   X-Real-IP $remote_addr;
            proxy_set_header   X-Forwarded-Host $http_host;
            proxy_redirect off;
            proxy_pass      http://127.0.0.1:8000;
        }
}
server {
        listen 443 default_server ssl;
        server_name     $hostname;
        ssl_certificate         /etc/nginx/ssl/py4web.crt;
        ssl_certificate_key     /etc/nginx/ssl/py4web.key;
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        ssl_ciphers ECDHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA:DHE-DSS-AES256-SHA:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        keepalive_timeout    70;
        location / {
            proxy_set_header   X-Forwarded-Proto $scheme;
            proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header   Host $http_host;
            proxy_set_header   X-Real-IP $remote_addr;
            proxy_set_header   X-Forwarded-Host $http_host;
            proxy_redirect off;
            proxy_pass      http://127.0.0.1:8000;
        }
        location ~* ^/(\w+)/static(?:/_[\d]+\.[\d]+\.[\d]+)?/(.*)$ {
            alias /home/www-data/py4web/apps/$1/static/$2;
            expires max;
        }
}' >/etc/nginx/sites-available/py4web
ln -s /etc/nginx/sites-available/py4web /etc/nginx/sites-enabled/py4web
rm /etc/nginx/sites-enabled/default
fi

if [ ! -f /etc/nginx/ssl/py4web.crt ]
then
    echo "======================================="
    echo "creating a self signed certificate"
    echo "======================================="
    mkdir -p /etc/nginx/ssl
    # pushd and popd do not work with sudo because it uses sh shell
    oldpath=`pwd`
    cd /etc/nginx/ssl
    # a 2048 bit key is needed nowadays
    openssl genrsa 2048 > py4web.key
    chmod 400 py4web.key
    openssl req -new -x509 -nodes -sha1 -days 1780 -key py4web.key > py4web.crt
    openssl x509 -noout -fingerprint -text < py4web.crt > py4web.info
    cd $oldpath
fi

if [ ! -f /etc/init.d/py4web ]
then

echo '
#! /bin/sh

NAME=py4web
DESC="py4web process"
PIDFILE="/var/run/${NAME}.pid"
LOGFILE="/var/log/${NAME}.log"
DAEMON="/usr/local/bin/py4web"
DAEMON_OPTS="run --password_file /home/www-data/py4web/password.txt /home/www-data/py4web/apps"
START_OPTS="--start --background --make-pidfile --pidfile ${PIDFILE} --exec ${DAEMON} -- ${DAEMON_OPTS}"
STOP_OPTS="--stop --oknodo --pidfile ${PIDFILE}"

test -x $DAEMON || exit 0
set -e

case "$1" in
start)
  echo -n "Starting ${DESC}: "
  start-stop-daemon $START_OPTS >> $LOGFILE
  echo "$NAME."
  ;;
stop)
  echo -n "Stopping $DESC: "
  start-stop-daemon $STOP_OPTS
  echo "$NAME."
  rm -f $PIDFILE
  ;;
restart|force-reload)
  echo -n "Restarting $DESC: "
  start-stop-daemon $STOP_OPTS
  sleep 1
  start-stop-daemon $START_OPTS >> $LOGFILE
  ;;
*)
  N=/etc/init.d/$NAME
  echo "Usage: $N {start|stop|restart|force-reload}" >&2
  exit 1
  ;;
esac
exit 0
' > /etc/init.d/py4web

fi

chmod +x /etc/init.d/py4web
echo Enter the password for py4web Dashboard:
py4web set_password --password_file=/home/www-data/py4web/password.txt
/etc/init.d/py4web restart
/etc/init.d/nginx restart
