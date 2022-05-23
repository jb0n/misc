#!/usr/bin/env bash

set -e

sudo apt-get install git vim
VIM_PLUGINS_DIR=~/.vim/pack/plugins/start

VIM_GO_URL=https://github.com/fatih/vim-go.git
VIM_GO_DIR=$VIM_PLUGINS_DIR/vim-go

ALE_URL=https://github.com/dense-analysis/ale.git
ALE_DIR=$VIM_PLUGINS_DIR/ale

GIT_URL=https://github.com/tpope/vim-fugitive.git
GIT_DIR=$VIM_PLUGINS_DIR/fugitive

function vim_plugin {
    if [ ! -d $2 ]
        then
        echo "installing $2"
        git clone --depth=1 $1 $2
    else
       echo "updating $2"
       cd $2 && git pull
    fi
}

mkdir -p $VIM_PLUGINS_DIR
vim_plugin $VIM_GO_URL $VIM_GO_DIR
vim_plugin $ALE_URL $ALE_DIR
vim_plugin $GIT_URL $GIT_DIR

