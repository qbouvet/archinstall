#!/usr/bin/env bash



## Variables
##
export __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
export __data="/setup-data";
export ssh_key_name="sshkey_pi_quentin";
export git_mail="quentin.bouvet@hotmail.fr";
export git_user="quentin";
export git_remote="git@github.com:sgPepper/rbpi.git";
export rbpi_git_dir="$HOME"/rbpi-git;   # source from bashrc




## autostart-login.sh
## 
printf "\n\n [autostart-login.sh]\n"
    # Put autostart.sh in user directory
cp "$__data"/autostart-login.sh "$HOME"/autostart-login.sh
chmod +x "$HOME"/autostart-login.sh;
    # Systemd service to start it up
mkdir -p "$HOME"/.config/systemd/user/;
cat >"$HOME"/.config/systemd/user/autostart-login.sh.service  <<EOF
# ~/.config/systemd/user/autostart-login.sh.service
[Unit]
Description="$USER" - autostart-login.sh

[Service]
Type=forking
ExecStart=/bin/bash %h/autostart-login.sh
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOF
chmod 744 "$HOME"/.config/systemd/user/autostart-login.sh.service;
    # enable service
systemctl --user enable autostart-login.sh;



## ssh-agent setup
##
printf "\n\n [ssh-agent setup]\n"
    # "Remember keys" setting
mkdir -p /home/"$USER"/.ssh/;
echo "AddKeysToAgent yes" > "$HOME"/.ssh/config;
    # Service : cf arch wiki
mkdir -p "$HOME"/.config/systemd/user/;
cat >"$HOME"/.config/systemd/user/ssh-agent.service <<EOF
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a \$SSH_AUTH_SOCK

[Install]
WantedBy=default.target    
EOF
echo 'SSH_AUTH_SOCK DEFAULT="${XDG_RUNTIME_DIR}/ssh-agent.socket"' >> "$HOME"/.pam_environment;
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"; # use without rebooting
chmod 744 "$HOME"/.config/systemd/user/ssh-agent.service;
    # Enable / start
systemctl --user enable ssh-agent;
systemctl --user start ssh-agent;
    # Add key & do first git commit so that key is remembered
sudo cp "$__data"/"$ssh_key_name" "$__data"/"$ssh_key_name".pub "$HOME"/.ssh;
sudo chown -R "$USER":users "$HOME"/.ssh;
ssh-add "$HOME"/.ssh/"$ssh_key_name";




## Git / github repo setup
##
printf "\n\n [Github repo setup]\n";
    # Global git config
git config --global user.email "$git_mail";
git config --global user.name "$git_user";
    # repo setup
mkdir -p "$rbpi_git_dir";
pushd "$rbpi_git_dir";
git init;
git remote add origin "$git_remote";
echo "  The 'Permission denied (publickey)' can be ignored if the subsequent commit completes";
ssh -o StrictHostKeyChecking=no github.com 1h;
git pull origin master;
    # One commit to make sure
print_ip > ip;
git add ip;
git commit -m "ip autocomit";
git push -u origin master;
popd;



exit 0 ;
systemctl --user stop ssh-agent;
systemctl --user disable ssh-agent;
rm /home/quentin/.config/systemd/user/ssh-agent.service;
cd;

