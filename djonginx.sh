#!/bin/bash

# Skript zur Installation von Django Oscar und Nginx auf Ubuntu 22.04

# Stelle sicher, dass das Skript als Root (oder mit Root rechten) ausgeführt wird
if [ "$(id -u)" != "0" ]; then
   echo "Dieses Skript muss als Root ausgeführt werden" 1>&2
   exit 1
fi

#rm -r #removes directory with content
#adduser klaus
#adduser klaus sudo
#logout
#login klaus

#download script from github etc # da muss ich noch schauen

wget https://www.dropbox.com/scl/fo/nov01cmrtzdzl88ure8yn/djonginx.sh

#chmod +x djonginx.sh
#sudo ./djonginx.sh


# Aktualisiere das System
echo "System wird aktualisiert..."
apt-get update && apt-get upgrade -y

# Installiere notwendige Pakete
echo "Notwendige Pakete werden installiert..."
apt-get install -y python3-pip python3-dev python3-venv libpq-dev nginx git

# Erstelle einen Benutzer für das Django-Projekt
echo "Django-Benutzer wird erstellt..."
#useradd -m -s /bin/bash Django
#usermod -aG sudo django

# Wechsle zum Django-Benutzer
#su - django <<'EOF'

# mkdir py3djaoscar - das zusätzliche Unterverzeichnis scheint nicht notwendig

python3 -m pip install virtualenv
python3 -m virtualenv envdjoscar
source envdjoscar/bin/activate

pip install wagtail #evtl außerhalb des virtualenv; problem, das installiert ein sehr aktuelles Django; 

pip3 install sorl-thumbnail

pip install 'django-oscar[sorl-thumbnail]'

pip3 install setuptools

wagtail start pollwerkshop . 

#sudo mv pollwerkshop/settings/base.py pollwerkshop/settings/base_old.py
#sudo chmod 777 pollwerkshop/settings
#change dir

wget https://www.dropbox.com/scl/fo/nov01cmrtzdzl88ure8yn/base.py

#      #hochladen base.py
#sudo chmod 755 pollwerkshop/settings
# ls envdjoscar/lib/python3.10/site-packages/oscar
#sudo mv envdjoscar/lib/python3.10/site-packages/oscar/defaults.py sudo mv envdjoscar/lib/python3.10/site-packages/oscar/defaults_old.py
#sudo mv envdjoscar/lib/python3.10/site-packages/oscar/config.py sudo mv envdjoscar/lib/python3.10/site-packages/oscar/config_old.py
# sudo chmod 777 envdjoscar/lib/python3.10/site-packages/oscar

wget https://www.dropbox.com/scl/fo/nov01cmrtzdzl88ure8yn/config.py

wget https://www.dropbox.com/scl/fo/nov01cmrtzdzl88ure8yn/defaults.py

#hochladen der 2 Dateien
# sudo chmod 755 envdjoscar/lib/python3.10/site-packages/oscar
# sudo chmod 777 pollwerkshop

wget https://www.dropbox.com/scl/fo/nov01cmrtzdzl88ure8yn/urls.py

#hochladen 1 Datei 
# sudo chmod 755 pollwerkshop 

pip install whitenoise 

#hochladen (ich muss zunächst die Verzeichhnisrechte von 755 auf 777 ändern; dann die alten Dateien umbenennen ):
#nach /home/klaus/pollwerkshop/settings.base.py
#nach /home/klaus/envdjoscar/lib/python3.10/site-packages/oscar #1. Config 2. Defaults
#nach /home/klaus/pollwerkshop/urls.py

python3 manage.py migrate 

python3 manage.py createsuperuser

# Klone das Oscar-Beispielprojekt
#echo "Oscar-Beispielprojekt wird geklont..."
#git clone https://github.com/django-oscar/django-oscar.git
#cd django-oscar

# Erstelle eine virtuelle Umgebung und aktiviere sie
#echo "Virtuelle Umgebung wird erstellt..."
#python3 -m venv oscar-env
##fehler, war nicht drin
#source oscar-env/bin/activate

# Installiere Django Oscar
#echo "Django Oscar wird installiert..."
#pip install -r requirements.txt

# Initialisiere die Datenbank
#echo "Datenbank wird initialisiert..."
#cd sandbox
#./manage.py migrate

# Sammle statische Dateien
#echo "Statische Dateien werden gesammelt..."
#./manage.py collectstatic --noinput

# Starte den Development-Server (nur zu Testzwecken, nicht für den Produktivbetrieb)
#echo "Development-Server wird gestartet..."
#./manage.py runserver 0.0.0.0:8000

#brauche ich nachfolgendes
cp -a  /Library/Frameworks/Python.framework/Versions/3.12/lib/python3.12/site-packages/oscar/static/oscar/* pollwerkshop/static

python3 manage.py runserver #funktioniert :-) #ich bin aber nicht in virtualenv


EOF #notwendig?

# /home/klaus/envdjoscar/lib/python3.10/site-packages/oscar #voranden alles wichtig
# /home/klaus/pollwerkshop/settings/base.py #wichtig, wie auch urls darüber

# sudo rm -r search  #/home/klaus/search #löschen
# sudo rm -r home    #/home/klaus/home #löschen





exit

# Konfiguriere Nginx als Reverse-Proxy
echo "Nginx wird konfiguriert..."
cat > /etc/nginx/sites-available/django_oscar <<EOF
server {
    listen 80;
    server_name _;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root /home/django/django-oscar/sandbox;
#	klaus /home/
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/django/django-oscar/sandbox/oscar.sock;
    }
}
EOF

# Aktiviere die Nginx-Konfiguration und starte Nginx neu
ln -s /etc/nginx/sites-available/django_oscar /etc/nginx/sites-enabled
nginx -t && systemctl restart nginx

echo "Django Oscar und Nginx wurden erfolgreich installiert und konfiguriert."

#lokaler test
# sudo apt install w3m #aufruf mit w3m URL
# sudo apr install elinks
# wget https://www.dropbox.com/s/ew2jket9lisdf4oor/example.zip
#https://www.dropbox.com/scl/fo/nov01cmrtzdzl88ure8yn/h?rlkey=u0j34cz0kydyi61tnjuzuwiiq&dl=0

https://www.dropbox.com/scl/fo/nov01cmrtzdzl88ure8yn/h?rlkey=u0j34cz0kydyi61tnjuzuwiiq&dl=0
