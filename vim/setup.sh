#!/usr/bin/env bash

set -e

sudo apt-get install git vim
VIM_PLUGINS_DIR=~/.vim/pack/plugins/start
VIM_GO_DIR=$VIM_PLUGINS_DIR/vim-go
ALE_DIR=$VIM_PLUGINS_DIR/ale


function vim_plugin {
    if [ ! -d $1 ]
        then
        echo "installing $1"
        git clone --depth=1 https://github.com/fatih/vim-go.git $1
    else
       echo "updating $1"
       cd $1 && git pull
    fi
}

vim_plugin $VIM_GO_DIR
vim_plugin $ALE_DIR

