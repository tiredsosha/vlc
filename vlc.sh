#!/bin/bash
if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as user: root"
        exit 255
fi

#samba
mkdir /home/$1/vlc/
mkdir /home/$1/vlc/music
sudo echo '[music]' >> /etc/samba/smb.conf
sudo echo '    comment = Backgroung music' >> /etc/samba/smb.conf
sudo echo "    path = /home/$1/vlc/music" >> /etc/samba/smb.conf
sudo echo '    read only = no' >> /etc/samba/smb.conf
sudo echo '    guest ok = yes' >> /etc/samba/smb.conf
sudo ufw allow samba
sudo service smbd restart

# user access
usermod -a -G sudo $1

a=$1
b='ALL=(ALL) NOPASSWD: ALL'
c="${a} ${b}"
sudo echo "${c}" >> /etc/sudoers ## проверить тут почему то не подставилось

# vlc install
apt --fix-broken install
sudo add-apt-repository ppa:videolan/stable-daily
sudo apt update
sudo apt install vlc

# vlc systemctl
sudo tee -a /home/$1/vlc/startvlc.sh <<EOF
#!/bin/bash
sudo chown -R $1: /home/$1/vlc/music
sudo chmod -R 777 /home/$1/vlc/music
vlc --http-password=hello88io --loop --no-repeat --playlist-autostart --one-instance --auto-preparse --intf http --volume-save /home/$1/vlc/music
EOF
sudo tee -a /lib/systemd/system/vlc.service <<EOF
[Unit]
Description=VLC Player
After=multi-user.target
[Service]
Restart=on-failure
RestartSec=5s
Type=simple
User=$1
WorkingDirectory=/home/$1/vlc/
ExecStart=/home/$1/vlc/startvlc.sh
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload 
sudo systemctl enable vlc.service 
sudo systemctl start vlc.service

wget "https://github.com/tiredsosha/vlc/releases/download/1.0.1/vlchttp" -O  /home/$1/vlc/vlchttp
sudo chmod +x /home/$1/vlc/vlchttp
# vlc http systemctl
sudo tee -a /lib/systemd/system/vlchttp.service <<EOF
[Unit]
Description=Simple http for VLC turn off
After=multi-user.target
[Service]
Restart=on-failure
RestartSec=5s
Type=simple
User=$1
ExecStart=/home/$1/vlc/vlchttp
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload 
sudo systemctl enable vlchttp.service 
sudo systemctl start vlchttp.service
sudo systemctl status vlchttp.service

# user access to vlc files
sudo chown -R $1: /home/$1/vlc/
sudo chmod -R 777 /home/$1/vlc/

# reboot
# sudo reboot