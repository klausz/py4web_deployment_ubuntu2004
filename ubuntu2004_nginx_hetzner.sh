sudo useradd klaus
adduser klaus sudo

sudo apt-get update && sudo apt-get upgrade -y
sudo apt install nginx
# setup firewall maybe









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


