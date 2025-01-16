"MDP configuration file for VIM - wsl

"fix a color bug in wsl
highlight Visual    ctermfg=NONE  ctermbg=grey guifg=NONE  guibg=grey
highlight Search    ctermfg=black ctermbg=grey guifg=black guibg=grey
highlight IncSearch ctermfg=black ctermbg=grey guifg=black guibg=grey

" send to windows clipboard
set clipboard=unnamedplus


"silence the vim bell
set noerrorbells
set visualbell
set t_vb=

"set the new fold on the right automatically
set splitright

"makes vim recognize and work with python
filetype indent plugin on

"set atomatic view save
augroup QuickNotes
  au BufWinLeave ?*.py mkview
  au BufWinEnter ?*.py silent loadview
augroup END


" F3 key mapping for results redirect  
" https://vim.fandom.com/wiki/Redirect_g_search_output
nnoremap <silent> <F3> :redir @a<CR>:g//<CR>:redir END<CR>:new<CR>:put! a<CR>

" F9 remap for running python code while editing
autocmd FileType python map <buffer> <F9> :w<CR>:exec '!python3' shellescape(@%, 1)<CR>
autocmd FileType python imap <buffer> <F9> <esc>:w<CR>:exec '!python3' shellescape(@%, 1)<CR>

"set a light grey bar on the 80th column
highlight ColorColumn ctermbg=grey guibg=grey  
set cc=80


"remap to avoid arrows!
inoremap <C-h> <Left>
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-l> <Right>
cnoremap <C-h> <Left>
cnoremap <C-j> <Down>
cnoremap <C-k> <Up>
cnoremap <C-l> <Right>
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>
inoremap <Up> <Nop>
inoremap <Down> <Nop>
inoremap <Left> <Nop>
inoremap <Right> <Nop>
cnoremap <Up> <Nop>
cnoremap <Down> <Nop>
cnoremap <Left> <Nop>
cnoremap <Right> <Nop>
