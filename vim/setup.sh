#!/usr/bin/env bash

set -e
#set -v

sudo apt-get install git vim
VIM_PLUGINS_DIR=~/.vim/pack/plugins/start

VIM_GO_URL=https://github.com/fatih/vim-go
ALE_URL=https://github.com/dense-analysis/ale
GIT_URL=https://github.com/tpope/vim-fugitive
EM_URL=https://github.com/easymotion/vim-easymotion
COMMITTIA_URL=https://github.com/rhysd/committia.vim


function vim_plugin {
    iname=$(basename "$1")
    idir=$VIM_PLUGINS_DIR/$iname
    if [ ! -d "$idir" ]
        then
        echo "installing $1"
        git clone --depth=1 "$1" "$idir"
    else
       echo "updating $1"
       cd "$idir" && git pull
       cd -
    fi
}

mkdir -p $VIM_PLUGINS_DIR
vim_plugin $VIM_GO_URL
vim_plugin $ALE_URL
vim_plugin $GIT_URL
vim_plugin $EM_URL
vim_plugin $COMMITTIA_URL

if [ ! -e ~/.vimrc ]
    then
        cp files/vimrc ~/.vimrc
fi

if [ ! -d ~/.vim/plugins ]
    then
    mkdir ~/.vim/plugins
fi

echo "$PWD"
if [ ! -e ~/.vim/plugins/ale.vim ]
        then
        cp files/ale.vim ~/.vim/plugins/ale.vim
fi

if [ ! -h ~/.vim/ale_linter.vim ]
    then
    ln -s ~/.vim/pack/plugins/start/ale/ale_linters/go/golangci_lint.vim ~/.vim/ale_linter.vim
fi


if [ ! -e ~/.fonts/Fira_Code_v6.2.zip ]
    then
    mkdir -p ~/.fonts
    cd ~/.fonts/
    wget https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip
    unzip Fira_Code_v6.2.zip
    fc-cache -f -v
    cd -
fi

if [ ! -e ~/.fonts/Hasklig-1.2.zip ]
    then
    mkdir -p ~/.fonts
    cd ~/.fonts/
    wget https://github.com/i-tu/Hasklig/releases/download/v1.2/Hasklig-1.2.zip
    unzip Hasklig-1.2.zip
    fc-cache -f -v
    cd -
fi

echo "ok, all set"

