#!/usr/bin/env bash

set -e

CENTOS_65_URL=https://github.com/2creatives/vagrant-centos/releases/download/v6.5.3/centos65-x86_64-20140116.box
CENTOS_65_BOX_FILE=~/.vagrant.d/boxes/centos-6.5/virtualbox/box.ovf

function ensure_vagrant_install {
    set +e
    which vagrant > /dev/null
    if [ $? -ne 0 ]; then
        which apt-get > /dev/null
        if [ $? -ne 0 ]; then
            echo "Please install vagrant"
            exit 1
        else    
            echo "Installing vagrant"
            sudo apt-get update
            sudo apt-get install vagrant
        fi
    else
        echo "Vagrant already installed"
    fi
    set -e
} 

function ensure_ssh_pub_key {
    set +e
    if [ ! -e ~/.ssh/id_rsa.pub ]; then
        echo "Creating RSA keys..."
        ssh-keygen
    fi
    set -e
}

ensure_vagrant_install
ensure_ssh_pub_key

if [ ! -f $CENTOS_65_BOX_FILE ]
then
    vagrant box add centos-6.5 $CENTOS_65_URL --provider virtualbox
fi

if [ ! -f Vagrantfile ]
then
    vagrant init centos-6.5
fi

vagrant up
#vagrant ssh -c "sudo yum update -y"
vagrant ssh -c "sudo yum install -y vim"

VIMRC=`cat vimrc`
vagrant ssh -c "echo '$VIMRC' > .vimrc"

SSH_PUB=`cat ~/.ssh/id_rsa.pub`
vagrant ssh -c "echo '$SSH_PUB' >> .ssh/authorized_keys"


vagrant ssh -c "echo \"alias vi='vim'\" >> .bashrc"
PROMPT="\[$(tput bold)\]\[$(tput setaf 3)\][\u@\h \W]\\$ \[$(tput sgr0)\]"
vagrant ssh -c "echo 'export PS1=\"$PROMPT\"' >> ~/.bashrc"

vagrant ssh -c "sudo bash -c \"echo '127.0.0.1   vagrant-centos65' >> /etc/hosts\""
vagrant ssh -c "sudo bash -c \"echo '127.0.0.1   vagrant-centos65.vagrantup.com' >> /etc/hosts\""

echo "SSHing in..."
vagrant ssh

