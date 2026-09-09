set modelines=0
set showmode
set laststatus=1
set cmdheight=1

" set clipboard=unnamedplus

color elflord

" turn on syntax highlighting
syntax on

" show line numbers
set number
set relativenumber

" folds
highlight! link Folded Normal
set foldmethod=indent
set foldenable
set foldlevelstart=99

" show file stats
set ruler

" set visual error instead of sound, then disable visual error
set visualbell
set t_vb=

" ignore case on search
set ignorecase

" enable file type detection and indents
filetype on
filetype indent on

" highlight cursor line
set cursorline

" keep 10 lines on top and bottom
set scrolloff=10

" searching ignore caps and incrementally search
set smartcase
set incsearch
set hlsearch
set showmatch

" show partial command you type in last line of the screen
set showcmd

" command menu list
set wildmenu

" set tabs formatting
set noexpandtab
set tabstop=4
set shiftwidth=4
set softtabstop=0 
" set expandtab

" set leader to space
let mapleader = " "
set timeout timeoutlen=500
set timeout ttimeoutlen=100

" print options
set printfont=courier:h11
set printoptions=paper:letter

" leader yank/paste to use system clipboard
nnoremap <leader>p "+p
nnoremap <leader>y "+yy
vnoremap <leader>y "+y

" paste most recent yank
nnoremap yp "0p
nnoremap cp "-p

" unselect search highlights by double tapping esc
nnoremap <silent> <esc><esc> :noh<return><esc>

"change cursor depending on mode
let &t_SI = "\<esc>[6 q"
let &t_EI = "\<esc>[2 q"

" Enable Spellcheck
autocmd FileType markdown,text setlocal spell spelllang=en_us

inoremap <expr> j pumvisible() ? "\<C-n>" : "j"
inoremap <expr> k pumvisible() ? "\<C-p>" : "k"
inoremap <expr> <Tab> pumvisible() ? "\<C-y><esc>" : "\<Tab>"
inoremap <expr> <CR> pumvisible() ? "\<C-y><esc>" : "\<CR>"
set pumheight=8
set spellsuggest=best,8
" set spellcapcheck

" Use Spell Suggestions
nnoremap zx i<C-x>s
nnoremap zv 1z=
nnoremap zh [s
nnoremap zl ]s

" Quickflash code to avrisp programmer
nnoremap <leader>r :w<CR>:!./quick-flash.sh<CR>

" Yank line, evaluate math expression, and paste result at end of line
nnoremap <leader>= ^vg_"cyA = <esc>"=eval(@c)<CR>p:echo""<CR>

" Highlight text on yanks
augroup highlightYankedText
    autocmd!
    autocmd TextYankPost * if v:event.operator ==# 'y' | call FlashYankedText() | endif
augroup END

function! FlashYankedText()
    let g:idTemporaryHighlight = matchadd('IncSearch', ".\\%>'\\[\\_.*\\%<']..")
    call timer_start(200, { -> execute('silent! call matchdelete(' . g:idTemporaryHighlight . ')') })
endfunction


