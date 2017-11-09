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
set listchars=eol:¬,nbsp:¤,space:⋅,trail:•,tab:››,extends:…,precedes:…,conceal:‡
set rtp+=~/.vim/bundle/Vundle.vim/ " set runtime path to use vundle for plugins

"----------------------------------------
" Start Vundle and loading plugins
"----------------------------------------
call vundle#begin()
Plugin 'VundleVim/Vundle.vim' "Best plugin management for vim
Plugin 'tpope/vim-rails' "Quick navigation in rails projects
Plugin 'pangloss/vim-javascript' "Better tabbing in javascript
Plugin 'othree/yajs.vim' "ES2015+ javascript support
Plugin 'othree/html5-syntax.vim' "Good html5 syntax support
Plugin 'moll/vim-node' "Allows gf/gF on relative node paths
Plugin 'kchmck/vim-coffee-script' "Coffeescript syntax
Plugin 'mtscout6/vim-cjsx' "Coffeescript JSX (CJSX)
Plugin 'slim-template/vim-slim' "Slim templating for Rails
Plugin 'digitaltoad/vim-pug' "Jade/Pug templating for Node
Plugin 'wavded/vim-stylus' "Stylus preprocessor for css
Plugin 'airblade/vim-gitgutter' "See git + / - / ~ in gutter
Plugin 'thaerkh/vim-workspace' "session save and load features
Plugin 'scrooloose/nerdtree' "File management
Plugin 'Xuyuanp/nerdtree-git-plugin' "Shows modifications in nerdtree
Plugin 'itchyny/lightline.vim' "pretty statusline
Plugin 'hail2u/vim-css3-syntax' "Support for latest css3
Plugin 'myusuf3/numbers.vim' "Shows relative line numbers on normal mode
Plugin 'ctrlpvim/ctrlp.vim' "Fuzzy file finder
Plugin 'scrooloose/nerdcommenter' "Allows commenting of lines easier
Plugin 'ap/vim-buftabline' "Allows the buffers as tabs
Plugin 'easymotion/vim-easymotion' "Allows quick movement around vim
Plugin 'chr4/nginx.vim' "nginx sytax support
call vundle#end()

filetype plugin indent on " Plugins default to indent

"---------------------------------------
" Reconfigure Plugin Options
"---------------------------------------
let NERDTreeQuitOnOpen = 1
let g:gitgutter_highlight_lines=1
let g:gitgutter_sign_added="++"
let g:gitgutter_sign_modified="~~"
let g:gitgutter_sign_removed="--"
let g:gitgutter_max_signs=3000
let g:ctrlp_map = '<c-p>' " ctrl+p starts plugin
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra' " start nearest search dir @ root .git
augroup VimCSS3Syntax
  autocmd!
  autocmd FileType css setlocal iskeyword+=-
augroup END
"---------------------------------------
" Keyboard mappings
"---------------------------------------
let mapleader="\<Space>"

" Session management
nnoremap <leader>s :ToggleWorkspace<CR>

" Open nerdtree and then open current file location in nerdtree
nmap \ :NERDTreeToggle<CR>
nmap <leader>\ :NERDTreeFind<CR>

" New buffers, quitting buffers
nmap <leader>T :enew<CR>
nmap <leader>bl :bnext<CR>
nmap <leader>bh :bprevious<CR>
nmap <leader>bq :bp <BAR> bd #<CR>
nmap <leader>bs :ls<CR>
nmap <leader>nj :rightbelow sb #<CR>
nmap <leader>nk :leftabove sb #<CR>
nmap <leader>nh :vert leftabove sb #<CR>
nmap <leader>nl :vert rightbelow sb #<CR>

" Indicate color code under cursor
nmap <leader>z :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

" Selecting, making and resizing windows
nnoremap <leader>j <C-w>j
nnoremap <leader>l <C-w>l
nnoremap <leader>h <C-w>h
nnoremap <leader>k <C-w>k
nnoremap <leader>mk <C-w>K
nnoremap <leader>mj <C-w>K<C-w>r
nnoremap <leader>mh <C-w>H
nnoremap <leader>ml <C-w>H<C-w>r
nnoremap <leader>sk :res +5<CR>
nnoremap <leader>sj :res -5<CR>
nnoremap <leader>sh :vertical res -5<CR>
nnoremap <leader>sl :vertical res +5<CR>
nnoremap j gj
nnoremap k gk

"---------------------------------------------
" ~Frost~ Highlight Theme (xterm256 required)
"---------------------------------------------
syntax on "Make sure syntax highlighting is on
hi clear "Start by clearing the screen

" Color Table for Theme
" 8   guifg=#808080 "rgb=128,128,128 (GRAYTONE)
" 29  guifg=#00875f "rgb=0,135,95 - deapsea approx.
" 52  guifg=#5f0000 "rgb=95,0,0 - rosewood approx.
" 60  guifg=#5f5f87 "rgb=95,95,135 - comet approx.
" 68  guifg=#5f87d7 "rgb=95,135,215 - havelock blue approx.
" 88  guifg=#870000 "rgb=135,0,0 - maroon approx.
" 97  guifg=#875faf "rgb=135,95,175 - deluge approx.
" 109 guifg=#87afaf "rgb=135,175,175 - gulf stream approx.
" 118 guifg=#87ff00 "rgb=135,255,0 - chartreuse approx.
" 130 guifg=#af5f00 "rgb=175,95,0 - rose of sharon approx.
" 131 guifg=#af5f5f "rgb=175,95,95 - matrix approx.
" 160 guifg=#d70000 "rgb=215,0,0 - guardsman red approx.
" 189 guifg=#d7d7ff "rgb=215,215,255 - fog approx.
" 196 guifg=#ff0000 "rgb=255,0,0 - red
" 209 guifg=#ff875f "rgb=255,135,95 - salmon approx.
" 226 guifg=#ffff00 "rgb=255,255,0 - yellow
" 233 guifg=#121212 "rgb=18,18,18 (GRAYTONE)
" 235 guifg=#262626 "rgb=38,38,38 (GRAYTONE)
" 236 guifg=#303030 "rgb=48,48,48 (GRAYTONE)
" 237 guifg=#3a3a3a "rgb=58,58,58 (GRAYTONE)
" 238 guifg=#444444 "rgb=68,68,68 (GRAYTONE)
" 239 guifg=#4e4e4e "rgb=78,78,78 (GRAYTONE)
" 241 guifg=#626262 "rgb=98,98,98 (GRAYTONE)
" 242 guifg=#6c6c6c "rgb=108,108,108 (GRAYTONE)
" 243 guifg=#767676 "rgb=118,118,118 (GRAYTONE)
" 246 guifg=#949494 "rgb=148,148,148 (GRAYTONE)
" 248 guifg=#a8a8a8 "rgb=168,168,168 (GRAYTONE)
" 249 guifg=#b2b2b2 "rgb=178,178,178 (GRAYTONE)
" 251 guifg=#c6c6c6 "rgb=198,198,198 (GRAYTONE)
" 252 guifg=#d0d0d0 "rgb=208,208,208 (GRAYTONE)
" 253 guifg=#dadada "rgb=218,218,218 (GRAYTONE)
" 254 guifg=#e4e4e4 "rgb=228,228,228 (GRAYTONE)

hi jsClassBraces   ctermfg=243 ctermbg=NONE cterm=NONE
hi jsFuncBraces    ctermfg=243 ctermbg=NONE cterm=NONE
hi jsFuncParens    ctermfg=243 ctermbg=NONE cterm=NONE
hi jsIfElseBraces  ctermfg=243 ctermbg=NONE cterm=NONE
hi jsParensIfElse  ctermfg=243 ctermbg=NONE cterm=NONE
hi jsParens        ctermfg=243 ctermbg=NONE cterm=NONE

" Background colors for invisibles and line numbers
hi NonText         ctermfg=239
hi SpecialKey      ctermfg=239
hi LineNr          ctermfg=241

" Buffer tab line colors
hi BufTabLineCurrent ctermfg=109 ctermbg=238 cterm=bold
hi BufTabLineActive  ctermfg=243 ctermbg=238 cterm=NONE
hi BufTabLineHidden  ctermfg=242
hi BufTabLineFill    ctermfg=242

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
