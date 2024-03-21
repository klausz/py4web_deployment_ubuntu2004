
#https://community.hetzner.com/tutorials/how-to-install-nginx-on-ubuntu-20-04
#wg Browser, ich brauche IPv4
adduser klaus
adduser klaus sudo

sudo apt-get update && sudo apt-get upgrade -y
sudo apt install nginx
# setup firewall maybe
sudo ufw app list
sudo ufw allow 'Nginx HTTP' #https geht auch, später
sudo ufw status #inaktiv, müsste aber aktiv sein
systemctl status nginx
http://65.109.168.3 #auf firefox gut, nicht auf Safari 
# eine Webseite hab eihc jetzt nicht erstellt, anleitung vorhanden

# https://community.hetzner.com/tutorials/add-ssl-certificate-with-lets-encrypt-to-nginx-on-ubuntu-20-04
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install certbot python3-certbot-nginx
sudo ufw status #geht immer noch nicht
sudo ufw allow 'Nginx Full'
sudo ufw delete allow 'Nginx HTTP'
sudo ufw status #geht immer noch nicht
sudo certbot --nginx -d example.com #evtl muss ich da eine eigene Domain nehmen
sudo certbot --nginx -d example.com -d www.example.com
# Your new Nginx config should look as follows: (muss ich wohl selbst einbauen)
#dann müsste es- wenn ich webseite habe, gehen 




========

#cloud-config

users:
  - name: holu
    groups: users, admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - <public_ssh_key>

packages:
  - fail2ban
  - ufw
package_update: true
package_upgrade: true

printf "[sshd]\nenabled = true\nbanaction = iptables-multiport" > /etc/fail2ban/jail.local
systemctl enable fail2ban

ufw allow OpenSSH
ufw enable

useradd -m -U -s /bin/bash -G sudo holu
passwd holu

PermitRootLogin no

ClientAliveInterval 300
ClientAliveCountMax 1

AllowUsers holu holu2

Host <yout_host>
    HostName <your_host>
    Port AUSGEWÄHLTER_PORT

MaxAuthTries 2

AllowTcpForwarding no   # Deaktiviert Port weiterleitungen.
X11Forwarding no        # Deaktiviert remote GUI ansicht.
AllowAgentForwarding no # Deaktiviert die weiterleitung des SSH Logins.
AuthorizedKeysFile .ssh/authorized_keys # Dabei sollte die Angabe der Datei ".ssh/authorized_keys2" entfernt werden.

sshd -t

systemctl restart sshd

apt install fail2ban
systemctl enable fail2ban

cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

#Changes:
enabled = true
port = AUSGEWÄHLTER_SSH_PORT

systemctl restart fail2ban


