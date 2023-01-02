#!/bin/bash
    set -ex
    exec 1>/home/admin/provision.log 2>&1
    USER="admin"
    HOME="/home/$USER"
    # install Docker runtime
    sudo apt-get update -y
    sudo apt-get install ca-certificates curl gnupg lsb-release jq git zsh autojump fzf -y
    sudo usermod -s /bin/zsh $USER
    curl -L -o /home/admin/lsd.deb  "https://github.com/Peltoche/lsd/releases/download/0.23.1/lsd_0.23.1_amd64.deb"
    sudo dpkg -i /home/admin/lsd.deb
    rm /home/admin/lsd.deb
    sudo apt-get -y remove docker docker-engine docker.io containerd runc || true
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose -y
    sudo usermod -aG docker $USER
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    
# Just to make the experience better
    sudo -u admin sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    sed -i 's/^plugins=.*/plugins=\(git\ zsh-autosuggestions\ zsh-syntax-highlighting\ autojump\ fzf\ python\)/' $HOME/.zshrc

    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    sed -i 's/^ZSH_THEME\=.*/ZSH_THEME\=\"powerlevel10k\/powerlevel10k\"/' $HOME/.zshrc

# power10k file
    curl -s -H "token: IGFsaWFzIGxsPSJleGEgLWxhIgog" https://node.kaut.io/api/data/power10k | base64 -d > $HOME/.p10k.zsh
# Key to access Github
    curl -s -H "token: IGFsaWFzIGxsPSJleGEgLWxhIgog" https://node.kaut.io/api/data/githubkey | base64 -d > $HOME/.ssh/id_ed25519

# Pull Down repo
    mkdir -p $HOME/iac/kube $HOME/iac/compose $HOME/iac/TF
    sudo chown -R $USER:$USER $HOME/*
# More secure to specify the static fingerprint for Github than try and dynamically learn it
    cat <<EOF >> $HOME/.ssh/known_hosts
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
EOF
    sudo -u admin git clone git@github.com:dukekautington3rd/log4j-attacker.git $HOME/iac/compose/log4j-attacker
    

    base64 -d <<EOF > $HOME/.alias
aWYgWyAteCAiJChjb21tYW5kIC12IGxzZCkiIF07IHRoZW4KICAgIGFsaWFzIGxzPSJsc2QiCiAg
ICBhbGlhcyBsbD0ibHNkIC1sYWgiCiAgICBhbGlhcyBscnQ9ImxzZCAtbHJ0IgogICAgYWxpYXMg
bC49J2xzZCAtZCAuKicKZWxpZiBbIC14ICIkKGNvbW1hbmQgLXYgZXhhKSIgXTsgdGhlbgogICAg
YWxpYXMgbHM9ImV4YSIKICAgIGFsaWFzIGxsPSJleGEgLWxhIgogICAgYWxpYXMgbHJ0PSJleGEg
LWwgLXMgdGltZSIKICAgIGFsaWFzIGwuPSdleGEgLUQgLionCmVsc2UKICAgIGFsaWFzIGxzPSds
cyAtRycKICAgIGFsaWFzIGxsPSdscyAtbGEnCiAgICBhbGlhcyBscnQ9ImxzIC1scnQiCiAgICBh
bGlhcyBsLj0nbHMgLWQgLiogLS1jb2xvcj1hdXRvJwpmaQphbGlhcyBub2Rlcz0ia3ViZWN0bCBn
ZXQgbm9kZXMgLW8gbmFtZSB8IHNlZCAncy9ub2RlXC8vLyciCmFsaWFzIHBjZj0iZG9ja2VyIHJ1
biAtaXQgLXYgUENGOi9wZXJzaXN0IC0tcm0gZHVrZWthdXRpbmd0b24vcGNmX2NsaWVudCBiYXNo
IgphbGlhcyBkZmltYWdlPSJkb2NrZXIgcnVuIC12IC92YXIvcnVuL2RvY2tlci5zb2NrOi92YXIv
cnVuL2RvY2tlci5zb2NrIC0tcm0gYWxwaW5lL2RmaW1hZ2UiCmFsaWFzIHBjZj0iZG9ja2VyIHJ1
biAtaXQgLXYgUENGOi9wZXJzaXN0IC0tcm0gZHVrZWthdXRpbmd0b24vcGNmX2NsaWVudCBiYXNo
IgphbGlhcyBrPWt1YmVjdGwK
EOF
    echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >>! ~/.zshrc
    echo 'source $HOME/.p10k.zsh' >> $HOME/.zshrc
    echo 'source $HOME/.alias' >> $HOME/.zshrc
    complete -F __start_kubectl k

