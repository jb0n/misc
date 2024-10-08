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
AIRLINE_URL=https://github.com/vim-airline/vim-airline

FIRA_URL=https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip
HASKLIG_URL=https://github.com/i-tu/Hasklig/releases/download/v1.2/Hasklig-1.2.zip


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

function install_font {
	fname=$(basename "$1")
	fdir=~/.fonts
	if [ ! -e $fdir/"$fname" ]
		then
		if [ ! -d "$fdir" ]
			then
			mkdir $fdir
		fi
		cd $fdir
		wget "$1"
		unzip "$fname"
		fc-cache -f -v
	    cd -
	fi
}

install_font $FIRA_URL
install_font $HASKLIG_URL

mkdir -p $VIM_PLUGINS_DIR
vim_plugin $VIM_GO_URL
vim_plugin $ALE_URL
vim_plugin $GIT_URL
vim_plugin $EM_URL
vim_plugin $COMMITTIA_URL
vim_plugin $AIRLINE_URL

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

vim -esN +GoInstallBinaries +q

echo "ok, all set"

