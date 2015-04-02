set tabstop=4 
set shiftwidth=4
set expandtab 
set hlsearch
set autoindent
colorscheme elflord

au BufEnter  [Mm]akefile*  set noet
au BufLeave  [Mm]akefile*  set et
au BufEnter  GNUmakefile*  set noet
au BufLeave  GNUmakefile*  set et
au BufEnter  gnumakefile*  set noet
au BufLeave  gnumakefile*  set et

" Save files with sudo rights
:command! W w !sudo tee % > /dev/null

set directory=~/tmp




" configure tags - add additional tags here or comment out not-used ones
set tags+=~/.vim/tags/cpp
set tags+=~/.vim/tags/gl
set tags+=~/.vim/tags/sdl
set tags+=~/.vim/tags/qt4
set tags+=./tags


" build tags of your own project with Ctrl-F12
map <C-F12> :!ctags -R --sort=yes --c++-kinds=+p --fields=+iaS --extra=+q .<CR>

"autocmd BufEnter ~/src/x/cloud_x/* :setlocal tags+=~/src/xx/cloud_x/tags
