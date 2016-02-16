"----------------------------------------
" Start general configurations
"----------------------------------------
set nocompatible " don't lose new vim features due to compatibility
set ts=2 sw=2 et " 2 space tabs (tabstop=2, shiftwidth=2, expandtab=true)
set autoindent "Always autoindent
set hlsearch " highlight search terms
set incsearch " show search while typing it
set smartcase " ignore case if search is lc, sensitive otherwise
set showmatch " set show matching parenthesis
set mouse=a " Allow mouse scrolling (peer programming) 
set backspace=indent,eol,start " Allow backspace to work normally
set number " Turn on line numbers
set laststatus=2 " Always show statusline
set list "Show invisible characters, next line specifies characters
set listchars=eol:¬,nbsp:¤,trail:•,tab:››,extends:…,precedes:…,conceal:‡
set rtp+=~/.vim/bundle/vundle/ " set runtime path to use vundle for plugins
call vundle#rc()

"----------------------------------------
" Start Vundle and loading plugins
"----------------------------------------
call vundle#begin()
Plugin 'gmarik/Vundle.vim' "Best plugin management for vim
Plugin 'slim-template/vim-slim' "Slim templating for Rails
Plugin 'digitaltoad/vim-jade' "Jade templating for Node
Plugin 'wavded/vim-stylus' "Stylus preprocessor for css
Plugin 'othree/yajs.vim' "ES2015+ javascript support
Plugin 'airblade/vim-gitgutter' "See git + / - / ~ in gutter
Plugin 'scrooloose/nerdtree' "File management
Plugin 'Xuyuanp/nerdtree-git-plugin' "Shows modifications in nerdtree
Plugin 'bling/vim-airline' "UI update to vim
Plugin 'hail2u/vim-css3-syntax' "Support for latest css3
Plugin 'myusuf3/numbers.vim' "Shows relative line numbers on normal mode
Plugin 'ctrlpvim/ctrlp.vim' "Fuzzy file finder
Plugin 'tpope/vim-rails' "Quick navigation in rails projects
Plugin 'pangloss/vim-javascript' "Better tabbing in javascript
Plugin 'leafgarland/typescript-vim' "Typescript syntax support
Plugin 'kchmck/vim-coffee-script' "Coffeescript syntax support
Plugin 'othree/html5-syntax.vim' "Good html5 syntax support
Plugin 'moll/vim-node' "Allows gf/gF on relative node paths
call vundle#end()

filetype plugin indent on " Plugins default to indent

"---------------------------------------
" Reconfigure Plugin Options
"---------------------------------------
let g:syntastic_javascript_checkers = ['eslint']
let g:indentLine_char="│" " Change indentation looks
let g:airline#extensions#tabline#enabled=1 " turn on buffer 'tabs'
let g:airline#extensions#tabline#fnamemod=':t' " change 'tab' names to just filename
let g:airline_powerline_fonts=1 " Ensure to use pretty powerline fonts
let NERDTreeQuitOnOpen = 1
let g:gitgutter_highlight_lines=1
let g:gitgutter_sign_added="++"
let g:gitgutter_sign_modified="~~"
let g:gitgutter_sign_removed="--"
let g:gitgutter_max_signs=3000
let g:ctrlp_map = '<c-p>' " ctrl+p starts plugin
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra' " start nearest search dir @ root .git
let g:javascript_conceal_function = "ƒ"
let g:javascript_conceal_null = "ø"
let g:javascript_conceal_this = "@"
let g:javascript_conceal_return = "⇚"
let g:javascript_conceal_undefined = "¿"
let g:javascript_conceal_NaN = "ℕ"
let g:javascript_conceal_prototype = "¶"
let g:javascript_conceal_static = "•"
let g:javascript_conceal_superc= "Ω"
augroup VimCSS3Syntax
  autocmd!
  autocmd FileType css setlocal iskeyword+=-
augroup END
"---------------------------------------
" Keyboard mappings
"---------------------------------------
let mapleader="\<Space>"
nmap \ :NERDTreeToggle<CR>
nmap <leader>T :enew<CR>
nmap <leader>bl :bnext<CR>
nmap <leader>bh :bprevious<CR>
nmap <leader>bq :bp <BAR> bd #<CR>
nmap <leader>bs :ls<CR>
nmap <leader>nj :rightbelow sb #<CR>
nmap <leader>nk :leftabove sb #<CR>
nmap <leader>nh :vert leftabove sb #<CR>
nmap <leader>nl :vert rightbelow sb #<CR>
nmap <leader>h :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>
nnoremap <leader>j <C-w>j
nnoremap <leader>l <C-w>l
nnoremap <leader>h <C-w>h
nnoremap <leader>k <C-w>k
nnoremap <leader>mk <C-w>K
nnoremap <leader>mj <C-w>K<C-w>r
nnoremap <leader>mh <C-w>H
nnoremap <leader>ml <C-w>H<C-w>r
nnoremap j gj
nnoremap k gk

"---------------------------------------------
" ~Frost~ Highlight Theme (xterm256 required)
"---------------------------------------------
syntax on "Make sure syntax highlighting is on

" Background colors for invisibles and line numbers
hi NonText         ctermfg=235
hi SpecialKey      ctermfg=235
hi LineNr          ctermfg=236

" Git Gutter and Git Diff
hi SignColumn      ctermfg=235 
hi GitGutterAdd    ctermfg=118  
hi GitGutterChange ctermfg=226  
hi GitGutterDelete ctermfg=160 
hi DiffAdd                      ctermbg=233  cterm=NONE
hi DiffChange                   ctermbg=233  cterm=NONE
hi DiffDelete                   ctermbg=233  cterm=NONE

" Plugin Specific highlighting
hi VendorPrefix    ctermfg=60   ctermbg=NONE cterm=bold
hi sassAmpersand   ctermfg=60   ctermbg=NONE cterm=bold
hi cssPseudoClass  ctermfg=60   ctermbg=NONE cterm=bold
hi cssNoise        ctermfg=68   ctermbg=NONE cterm=NONE
hi sassProperty    ctermfg=68   ctermbg=NONE cterm=NONE
hi cssValueLength  ctermfg=109  ctermbg=NONE cterm=NONE
hi cssValueNumber  ctermfg=109  ctermbg=NONE cterm=NONE
hi cssPositioningAttr ctermfg=109 ctermbg=NONE cterm=NONE
hi cssUnitDecorators ctermfg=109 ctermbg=NONE cterm=NONE
hi cssFontAttr     ctermfg=109  ctermbg=NONE cterm=NONE
hi cssBoxAttr      ctermfg=109  ctermbg=NONE cterm=NONE
hi cssCommonAttr   ctermfg=109  ctermbg=NONE cterm=NONE
hi cssBorderAttr   ctermfg=109  ctermbg=NONE cterm=NONE
hi cssColor        ctermfg=109  ctermbg=NONE cterm=NONE
match VendorPrefix /-\(moz\|webkit\|o\|ms\)-[a-zA-Z-]\+/

" General colors
hi Normal          ctermfg=248  ctermbg=NONE cterm=NONE
hi IncSearch       ctermfg=248  ctermbg=52   cterm=NONE
hi WildMenu        ctermfg=NONE ctermbg=248  cterm=NONE
hi SpecialComment  ctermfg=68   ctermbg=NONE cterm=NONE
hi Comment         ctermfg=29   ctermbg=NONE cterm=NONE
hi Typedef         ctermfg=60   ctermbg=NONE cterm=bold
hi Title           ctermfg=249  ctermbg=52   cterm=bold
hi Folded          ctermfg=235  ctermbg=248  cterm=bold
hi PreCondit       ctermfg=69   ctermbg=NONE cterm=NONE
hi Include         ctermfg=68   ctermbg=NONE cterm=NONE
hi Float           ctermfg=248  ctermbg=NONE cterm=NONE
hi StatusLineNC    ctermfg=248  ctermbg=239  cterm=bold
hi ErrorMsg        ctermfg=252  ctermbg=130  cterm=NONE
hi Debug           ctermfg=68   ctermbg=NONE cterm=NONE
hi PMenuSbar       ctermfg=NONE ctermbg=8    cterm=NONE
hi Identifier      ctermfg=68   ctermbg=NONE cterm=NONE
hi SpecialChar     ctermfg=68   ctermbg=NONE cterm=NONE
hi Conditional     ctermfg=68   ctermbg=NONE cterm=bold
hi StorageClass    ctermfg=60   ctermbg=NONE cterm=bold
hi Todo            ctermfg=196  ctermbg=235  cterm=NONE
hi Special         ctermfg=68   ctermbg=NONE cterm=NONE
hi StatusLine      ctermfg=248  ctermbg=52   cterm=bold
hi Label           ctermfg=68   ctermbg=NONE cterm=bold
hi PMenuSel        ctermfg=248  ctermbg=52   cterm=NONE
hi Search          ctermfg=248  ctermbg=52   cterm=NONE
hi Delimiter       ctermfg=68   ctermbg=NONE cterm=NONE
hi Statement       ctermfg=69   ctermbg=NONE cterm=bold
hi SpellRare       ctermfg=189  ctermbg=235  cterm=underline
hi Character       ctermfg=248  ctermbg=NONE cterm=NONE
hi TabLineSel      ctermfg=248  ctermbg=52   cterm=bold
hi Number          ctermfg=251  ctermbg=NONE cterm=NONE
hi Boolean         ctermfg=248  ctermbg=NONE cterm=NONE
hi Operator        ctermfg=253  ctermbg=NONE cterm=bold
hi CursorLine      ctermfg=NONE ctermbg=237  cterm=NONE
hi TabLineFill     ctermfg=235  ctermbg=239  cterm=bold
hi WarningMsg      ctermfg=248  ctermbg=88   cterm=NONE
hi VisualNOS       ctermfg=235  ctermbg=189  cterm=underline
hi ModeMsg         ctermfg=253  ctermbg=235  cterm=bold
hi CursorColumn    ctermfg=NONE ctermbg=236  cterm=NONE
hi Define          ctermfg=68   ctermbg=NONE cterm=NONE
hi Function        ctermfg=60   ctermbg=NONE cterm=bold
hi FoldColumn      ctermfg=235  ctermbg=248  cterm=bold
hi PreProc         ctermfg=97   ctermbg=NONE cterm=NONE
hi Visual          ctermfg=248  ctermbg=52   cterm=NONE
hi MoreMsg         ctermfg=68   ctermbg=NONE cterm=bold
hi SpellCap        ctermfg=189  ctermbg=235  cterm=underline
hi VertSplit       ctermfg=235  ctermbg=239  cterm=bold
hi Exception       ctermfg=68   ctermbg=NONE cterm=bold
hi Keyword         ctermfg=68   ctermbg=NONE cterm=bold
hi Type            ctermfg=60   ctermbg=NONE cterm=bold
hi Cursor          ctermfg=254  ctermbg=131  cterm=NONE
hi SpellLocal      ctermfg=189  ctermbg=235  cterm=underline
hi Error           ctermfg=248  ctermbg=88   cterm=NONE
hi PMenu           ctermfg=248  ctermbg=235  cterm=NONE
hi Constant        ctermfg=248  ctermbg=NONE cterm=NONE
hi Tag             ctermfg=68   ctermbg=NONE cterm=NONE
hi String          ctermfg=109  ctermbg=NONE cterm=NONE
hi PMenuThumb      ctermfg=254  ctermbg=248  cterm=NONE
hi MatchParen      ctermfg=68   ctermbg=NONE cterm=bold
hi LocalVariable   ctermfg=209  ctermbg=NONE cterm=bold
hi Repeat          ctermfg=68   ctermbg=NONE cterm=bold
hi SpellBad        ctermfg=189  ctermbg=235  cterm=underline
hi Directory       ctermfg=60   ctermbg=NONE cterm=bold
hi Structure       ctermfg=60   ctermbg=NONE cterm=bold
hi Macro           ctermfg=68   ctermbg=NONE cterm=NONE
hi Underlined      ctermfg=189  ctermbg=235  cterm=underline
hi TabLine         ctermfg=235  ctermbg=246  cterm=bold
hi cursorim        ctermfg=235  ctermbg=52   cterm=NONE
hi colorcolumn     ctermfg=NONE ctermbg=237  cterm=NONE
"hi CTagsClass -- no settings --
"hi clear -- no settings --
"hi DefinedName -- no settings --
"hi EnumerationName -- no settings --
"hi MarkdownCodeBlock guifg=#dedede guibg=NONE guisp=NONE gui=BOLD
"hi CTagsMember -- no settings --
"hi CTagsGlobalConstant -- no settings --
"hi Ignore -- no settings --
"hi CTagsImport -- no settings --
"hi CTagsGlobalVariable -- no settings --
"hi EnumerationValue -- no settings --
"hi Question -- no settings --
"hi Union -- no settings --

