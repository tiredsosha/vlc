#!/bin/bash
if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as user: root"
        exit 255
fi

#samba
mkdir /home/$1/vlc/
mkdir /home/$1/vlc/music
apt --fix-broken install
sudo apt-get update
sudo apt update
sudo apt install samba
sudo echo '[music]' >> /etc/samba/smb.conf
sudo echo '    comment = Backgroung music' >> /etc/samba/smb.conf
sudo echo '    path = /home/$1/vlc/music' >> /etc/samba/smb.conf
sudo echo '    read only = no' >> /etc/samba/smb.conf
sudo echo '    guest ok = yes' >> /etc/samba/smb.conf
sudo ufw allow samba
sudo service smbd restart

# user access
usermod -a -G sudo $1
sudo echo '%LimitedAdmins ALL=NOPASSWD: /bin/systemctl vlc.service' >> /etc/sudoers ## проверить тут почему то не подставилось

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
StartLimitIntervalSec=500
StartLimitBurst=5
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

# vlc http server
tee -a /home/$1/vlc/simplevlc.py <<EOF
#!/usr/bin/env python3.6


from http.server import BaseHTTPRequestHandler, HTTPServer


class S(BaseHTTPRequestHandler):
    def _set_response(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_GET(self):
        self._set_response()

        from os import system

        system('sudo systemctl restart vlc.service')


def run(server_class=HTTPServer, handler_class=S, port=8080):
    server_address = ('', 8000)
    httpd = server_class(server_address, handler_class)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()


if __name__ == '__main__':
    run()
EOF

# vlc http systemctl
sudo tee -a /lib/systemd/system/vlchttp.service <<EOF
[Unit]
Description=Simple http for VLC turn on
After=multi-user.target
StartLimitIntervalSec=500
StartLimitBurst=5
[Service]
Restart=on-failure
RestartSec=5s
Type=simple
User=$1
WorkingDirectory=/home/$1/vlc/
ExecStart=/home/$1/vlc/simplevlc.py
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload 
sudo systemctl enable vlchttp.service 
sudo systemctl start vlchttp.service

# user access to vlc files
sudo chown -R $1: /home/$1/vlc/
sudo chmod -R 777 /home/$1/vlc/

# reboot
sudo reboot