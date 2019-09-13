set tabstop=4 
set shiftwidth=4
set expandtab 
set hlsearch
set autoindent
colorscheme koehler

au BufEnter  [Mm]akefile*  set noet
au BufLeave  [Mm]akefile*  set et
au BufEnter  GNUmakefile*  set noet
au BufLeave  GNUmakefile*  set et
au BufEnter  gnumakefile*  set noet
au BufLeave  gnumakefile*  set et

au BufNewFile,BufRead *.py set expandtab

" Save files with sudo rights
:command! W w !sudo tee % > /dev/null

" build tags of your own project with Ctrl-F12
:map <F12> :ALEToggle<CR>

set tags=/home/jgould/src/cs/golang/src/tags,tags;

hi Search cterm=NONE ctermfg=black ctermbg=yellow




call plug#begin()
Plug 'davidhalter/jedi-vim'
Plug 'easymotion/vim-easymotion'
Plug 'fatih/vim-go'
Plug 'nsf/gocode', { 'rtp': 'vim', 'do': '~/.vim/plugged/gocode/vim/symlink.sh' }
Plug 'rogpeppe/godef'
Plug 'scrooloose/nerdcommenter'
Plug 'tpope/vim-fugitive'
"Plug 'valloric/youcompleteme'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
call plug#end()

" ALE config
let g:ale_linters = {
    \'go': ['gofmt', 'go tool vet', 'golint', 'go build', 'errcheck', 'megacheck']
\}
let g:ale_lint_on_text_changed = 0
let g:ale_lint_on_enter = 0
let g:ale_lint_on_save = 1
let g:ale_sign_error = '❯'
let g:ale_sign_warning = '❯'
highlight ALEErrorSign ctermbg=NONE ctermfg=red
highlight ALEWarningSign ctermbg=NONE ctermfg=yellow



" Load all plugins now.
" Plugins need to be added to runtimepath before helptags can be generated.
packloadall
" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
silent! helptags ALL

com! FormatJSON %!python -m json.tool

