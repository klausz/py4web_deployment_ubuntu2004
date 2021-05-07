#taken from David Orme https://github.com/web2py/web2py/blob/master/scripts/setup-web2py-nginx-uwsgi-ubuntu-focal.sh and modified
#!/bin/bash
echo 'setup-py4web-nginx-uwsgi-ubuntu-focal.sh'
echo 'Requires Ubuntu > 20.04 and installs Nginx + uWSGI + py4web'
# Check if user has root privileges
if [[ $EUID -ne 0 ]]; then
   echo "You must run the script as root or using sudo"
   exit 1
fi
# parse command line arguments
nopassword=0
nocertificate=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-password) nopassword=1; shift 1;;
    --no-certificate) nocertificate=1; shift 1;;
  esac
done
# Get Web2py Admin Password
if [ "$nopassword" -eq 0 ]
then
  echo -e "To be stored new py4web Admin Password: \c "
  read -s PW
  printf "\n"  # fix no new line artifact of "read -s" to avoid cleartext password
fi
# Upgrade and install needed software
apt-get update
apt-get -y upgrade
apt-get autoremove
apt-get autoclean
apt-get -y install nginx-full

apt-get -y install build-essential python3-dev libxml2-dev python3-pip unzip
pip3 install setuptools --no-binary :all: --upgrade
PIPPATH=`which pip3`
$PIPPATH install --upgrade uwsgi

# Create common nginx sections
mkdir /etc/nginx/conf.d/py4web
#mkdir /etc/nginx/conf.d/web2py
echo '
gzip_static on;
gzip_http_version   1.1;
gzip_proxied        expired no-cache no-store private auth;
gzip_disable        "MSIE [1-6]\.";
gzip_vary           on;
' > /etc/nginx/conf.d/py4web/gzip_static.conf
#' > /etc/nginx/conf.d/web2py/gzip_static.conf
echo '
gzip on;
gzip_disable "msie6";
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
' > /etc/nginx/conf.d/py4web/gzip.conf
#' > /etc/nginx/conf.d/web2py/gzip.conf
# Create configuration file /etc/nginx/sites-available/py4web
## Create configuration file /etc/nginx/sites-available/web2py
echo 'server {
        listen          80;
        server_name     $hostname;
        ###to enable correct use of response.static_version
        location ~* ^/(\w+)/static(?:/_[\d]+\.[\d]+\.[\d]+)?/(.*)$ {
            alias /home/www-data/py4web/applications/$1/static/$2;
#            alias /home/www-data/web2py/applications/$1/static/$2;
            expires max;
            ### if you want to use pre-gzipped static files (recommended)
            ### check scripts/zip_static_files.py and remove the comments
            # include /etc/nginx/conf.d/web2py/gzip_static.conf;
        }
        ###

        ###if you use something like myapp = dict(languages=['en', 'it', 'jp'], default_language='en') in your routes.py
        #location ~* ^/(\w+)/(en|it|jp)/static/(.*)$ {
        #    alias /home/www-data/web2py/applications/$1/;
        #    try_files static/$2/$3 static/$3 =404;
        #}
        ###
        
        location / {
            #uwsgi_pass      127.0.0.1:9001;
            uwsgi_pass      unix:///tmp/py4web.socket;
#            uwsgi_pass      unix:///tmp/web2py.socket;
            include         uwsgi_params;
            uwsgi_param     UWSGI_SCHEME $scheme;
            uwsgi_param     SERVER_SOFTWARE    nginx/$nginx_version;

            ###remove the comments to turn on if you want gzip compression of your pages
            # include /etc/nginx/conf.d/web2py/gzip.conf;
            ### end gzip section

            ### remove the comments if you use uploads (max 10 MB)
            #client_max_body_size 10m;
            ###
        }
}
server {
        listen 443 default_server ssl;
        server_name     $hostname;
        ssl_certificate         /etc/nginx/ssl/py4web.crt;
        ssl_certificate_key     /etc/nginx/ssl/py4web.key;
#        ssl_certificate         /etc/nginx/ssl/web2py.crt;
#        ssl_certificate_key     /etc/nginx/ssl/web2py.key;
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        ssl_ciphers ECDHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA:DHE-DSS-AES256-SHA:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        keepalive_timeout    70;
        location / {
            #uwsgi_pass      127.0.0.1:9001;
            uwsgi_pass      unix:///tmp/py4web.socket;
#            uwsgi_pass      unix:///tmp/web2py.socket;
            include         uwsgi_params;
            uwsgi_param     UWSGI_SCHEME $scheme;
            uwsgi_param     SERVER_SOFTWARE    nginx/$nginx_version;
            ###remove the comments to turn on if you want gzip compression of your pages
            # include /etc/nginx/conf.d/web2py/gzip.conf;
            ### end gzip section
            ### remove the comments if you want to enable uploads (max 10 MB)
            #client_max_body_size 10m;
            ###
        }
        ###to enable correct use of response.static_version
        location ~* ^/(\w+)/static(?:/_[\d]+\.[\d]+\.[\d]+)?/(.*)$ {
            alias /home/www-data/py4web/apps/$1/static/$2;
#            alias /home/www-data/web2py/applications/$1/static/$2;
            expires max;
            ### if you want to use pre-gzipped static files (recommended)
            ### check scripts/zip_static_files.py and remove the comments
            # include /etc/nginx/conf.d/web2py/gzip_static.conf;
        }
        ###

}' >/etc/nginx/sites-available/py4web
#}' >/etc/nginx/sites-available/web2py

ln -s /etc/nginx/sites-available/py4web /etc/nginx/sites-enabled/py4web
#ln -s /etc/nginx/sites-available/web2py /etc/nginx/sites-enabled/web2py
rm /etc/nginx/sites-enabled/default
mkdir /etc/nginx/ssl
cd /etc/nginx/ssl
if [ "$nocertificate" -eq 0 ]
then
    openssl req -x509 -nodes -sha256 -days 365 -newkey rsa:2048 -keyout py4web.key -out py4web.crt
    openssl x509 -noout -text -in py4web.crt -out py4web.info
#    openssl req -x509 -nodes -sha256 -days 365 -newkey rsa:2048 -keyout web2py.key -out web2py.crt
#    openssl x509 -noout -text -in web2py.crt -out web2py.info
fi
# Prepare folders for uwsgi
sudo mkdir /etc/uwsgi
sudo mkdir /var/log/uwsgi
sudo mkdir /etc/systemd
sudo mkdir /etc/systemd/system

#uWSGI Emperor
echo '[Unit]
Description = uWSGI Emperor
After = syslog.target

[Service]
ExecStart = uwsgi --master --die-on-term --emperor /etc/uwsgi --logto /var/log/uwsgi/uwsgi.log
RuntimeDirectory = uwsgi
Restart = always
KillSignal = SIGQUIT
Type = notify
StandardError = syslog
NotifyAccess = all

[Install]
WantedBy = multi-user.target
' > /etc/systemd/system/emperor.uwsgi.service

# Create configuration file /etc/uwsgi/web2py.ini
echo '[uwsgi]

socket = /tmp/py4web.socket
#socket = /tmp/web2py.socket
pythonpath = /home/www-data/py4web/
#pythonpath = /home/www-data/web2py/
mount = /=wsgihandler:application
processes = 4
master = true
harakiri = 60
reload-mercy = 8
cpu-affinity = 1
stats = /tmp/stats.socket
max-requests = 2000
limit-as = 512
reload-on-as = 256
reload-on-rss = 192
uid = www-data
gid = www-data
touch-reload = /home/www-data/py4web/routes.py
#touch-reload = /home/www-data/web2py/routes.py
cron = 0 0 -1 -1 -1 python3 /home/www-data/py4web/apps -Q -S welcome -M -R scripts/sessions2trash.py -A -o
#cron = 0 0 -1 -1 -1 python3 /home/www-data/web2py/web2py.py -Q -S welcome -M -R scripts/sessions2trash.py -A -o
no-orphans = true
' >/etc/uwsgi/py4web.ini
#' >/etc/uwsgi/web2py.ini

#Install py4web
## Install Web2py # Can i remoove one directory level?
mkdir /home/www-data
cd /home/www-data
wget https://github.com/web2py/py4web/archive/refs/heads/master.zip
# unzip py4web-master.zip
unzip master.zip
# wget https://github.com/web2py/py4web/py4web-master.zip #if this line works, nowhere such an installation is recommended, i can remove min 3 lines .git clone .. run_apps ? below
#wget http://web2py.com/examples/static/web2py_src.zip
#git clone https://github.com/web2py/py4web.git
#cd py4web
cd py4web-master
python3 -m pip install  --upgrade -r requirements.txt
# I think tornado as additional webserver is not needed
./py4web.py setup apps
./py4web.py set_password
#here i need to define ngix and ip of server
./py4web.py run apps -H 195.201.236.155 -P 8000 -s wsgiref
# ./py4web.py run apps #what IP has to be used, the server IP?

# then set wsgi - wsgiref ?
#  -s, --server [default|wsgiref|tornado|gunicorn|gevent|waitress|
#                geventWebSocketServer|wsgirefThreadingServer|rocketServer]
#                              server to use  [default: default]

# --ssl_cert PATH               SSL certificate file for HTTPS
# --ssl_key PATH                SSL key file for HTTPS


#wget http://web2py.com/examples/static/web2py_src.zip
#unzip web2py_src.zip
#mv web2py/handlers/wsgihandler.py web2py/wsgihandler.py
#rm web2py_src.zip
chown -R www-data:www-data py4web
#chown -R www-data:www-data web2py
cd /home/www-data/py4web
#cd /home/www-data/web2py
#if [ "$nopassword" -eq 0 ]
#then
#   sudo -u www-data python3 -c "from gluon.main import save_password; save_password('$PW',443)"
#fi

/etc/init.d/nginx start
systemctl start emperor.uwsgi.service
systemctl enable emperor.uwsgi.service

echo <<EOF
you can stop uwsgi and nginx with

  sudo /etc/init.d/nginx stop
  sudo systemctl stop emperor.uwsgi.service
 
and start it with

  sudo /etc/init.d/nginx start
  systemctl start emperor.uwsgi.service

EOF

