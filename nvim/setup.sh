#!/usr/bin/env bash

set -e
#set -v

NVIM_PLUGINS_DIR=~/.local/share/nvim/site/pack/plugins/start
NVIM_GO_URL=https://github.com/fatih/vim-go
ALE_URL=https://github.com/dense-analysis/ale
GIT_URL=https://github.com/tpope/vim-fugitive
EM_URL=https://github.com/easymotion/vim-easymotion
COMMITTIA_URL=https://github.com/rhysd/committia.vim
AIRLINE_URL=https://github.com/vim-airline/vim-airline
RAINBOW_URL=https://gitlab.com/HiPhish/rainbow-delimiters.nvim

function nvim_plugin {
    iname=$(basename "$1")
    idir=$NVIM_PLUGINS_DIR/$iname
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

mkdir -p $NVIM_PLUGINS_DIR
#nvim_plugin $NVIM_GO_URL
#nvim_plugin $ALE_URL
#nvim_plugin $GIT_URL
#nvim_plugin $EM_URL
#nvim_plugin $COMMITTIA_URL
#nvim_plugin $AIRLINE_URL
#nvim_plugin $RAINBOW_URL

if [ ! -e ~/.config/nvim/init.vim ]
    then
    mkdir -p ~/.config/nvim/
    cp files/init.vim ~/.config/nvim/init.vim
fi
mkdir -p ~/.config/nvim/colors/
cp files/eldar.vim ~/.config/nvim/colors/

nvim -esN +GoInstallBinaries +q

echo "ok, all set"

