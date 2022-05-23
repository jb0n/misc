#!/usr/bin/env bash

set -e
set -v

sudo apt-get install git vim
VIM_PLUGINS_DIR=~/.vim/pack/plugins/start

VIM_GO_URL=https://github.com/fatih/vim-go

ALE_URL=https://github.com/dense-analysis/ale

GIT_URL=https://github.com/tpope/vim-fugitive

function vim_plugin {
    iname=$(basename $1)
    idir=$VIM_PLUGINS_DIR/$iname
    if [ ! -d $idir ]
        then
        echo "installing $1"
        git clone --depth=1 $1 $idir
    else
       echo "updating $1"
       cd $idir && git pull
    fi
}

mkdir -p $VIM_PLUGINS_DIR
vim_plugin $VIM_GO_URL
vim_plugin $ALE_URL
vim_plugin $GIT_URL



#TODO: .vimrc, ale config
mkdir -p ~/.fonts
cd ~/.fonts/
wget https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip
unzip Fira_Code_v6.2.zip
fc-cache -f -v
``

