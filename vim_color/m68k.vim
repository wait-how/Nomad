" vim m68k syntax file
" copy to ~/.vim/syntax/m68k.vim
" create ~/.vim/ftdetect/m68k.vim, paste:
" au BufRead,BufNewFile *.asm68k set filetype=m68k

" test if current syntax exists already
if exists("b:current_syntax")
	finish
endif

syn keyword m68k_instructions move or ori
syn keyword m68k_instructions andi cmp

syn match m68k_literal '#[0x]*[0-9a-fA-F]+'

syn keyword m68k_todo contained todo TODO note NOTE
syn match m68k_comment '|.*' contains=todo

let b:current_syntax = "m68k"

hi def link m68k_instructions	Instructions
hi def link m68k_literal		Literal
hi def link m68k_todo			Todo
hi def link m68k_comment		Comment


