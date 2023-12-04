version=10300
date equ 2017.09.01 15:03:51
;true=1 => true=-1=0xffffffff

;2017.09.01 15:03:51 1.03.00 2over, new variables
;2017.06.20 19:02:13 1.02.00 string compare, search
;2017.06.10 17:12:20 deferred refill

format PE console 4.0
entry	start

include 'win32a.inc'


debug_names=0


section '.text' code readable executable
;section '.text' code readable writable executable

cell_size = 4


macro next_eax{ jmp dword [eax] }

macro next{
	lodsd
	next_eax
}

macro rpush reg{
	lea ebp,[ebp-4]
	mov dword [ebp],reg
}

macro rpop reg{
	mov reg, dword [ebp]
	lea ebp,[ebp+4]
}



start:
	cld
	invoke GetStdHandle,-11
	mov [var_stdout],eax
	invoke GetStdHandle,-10
	mov [var_stdin],eax
	mov [var_sourceid],eax
	mov [var_s0],esp
	mov ebp,return_stack_top
	mov esi,forth_start
	next
exitapp:
	invoke ExitProcess,0

docol:
	rpush esi
	add eax,4
	mov esi,eax
	next

forth_start:
;	dd wquit
	dd wlit,source_str,wlit,source_stre-source_str
	dd wlit,wevaluate,wcatch,wdrop,wbye


	f_immed = 0x80
	f_hidden = 0x40
	f_lenmask = 0x1f
	link = 0


macro defheader name,len,flags=0,label{
	align 4
	local record
  record:
	dd link
	link = record
	db flags+len
	db name
	align 4
  w#label:
}

macro defword name,len,flags=0,label{
	defheader name,len,flags,label
	dd docol
if debug_names
	dd wslit,.debt2-$-4
	db "|",name,13,10
.debt2	db 0
	align 4
	dd wtype
end if
}

macro defcode name,len,flags=0,label{
	defheader name,len,flags,label
	local code
	dd code
  code:
if debug_names
	jmp .stre
  .str	db name,13,10
  .stre:
	push eax
	mov ecx,esp
	invoke WriteFile,[var_stdout],.str,.stre-.str,ecx,0
	pop eax
end if
}



;******************************
;** basic words (stack, ops etc.)

	defcode "drop",4,,drop
	pop eax
	next

	defcode "swap",4,,swap
	pop eax
	pop ebx
	push eax
	push ebx
	next

	defcode "dup",3,,dup
	mov eax,[esp]
	push eax
	next

	defcode "over",4,,over
	mov eax,[esp+4]
	push eax
	next

	defcode "rot",3,,rot
	pop ecx
	pop ebx
	pop eax
	push ebx
	push ecx
	push eax
	next

	defcode "-rot",4,,nrot
	pop ecx
	pop ebx
	pop eax
	push ecx
	push eax
	push ebx
	next

	defcode "nip",3,,nip
	pop eax
	mov [esp],eax
	next

	defcode "tuck",4,,tuck
	pop ebx
	pop eax
	push ebx
	push eax
	push ebx
	next

	defcode "2drop",5,,2drop
	pop eax
	pop eax
	next

	defcode "2dup",4,,2dup
	mov eax,[esp]
	mov ebx,[esp+4]
	push ebx
	push eax
	next

	defcode "2swap",5,,2swap
	pop edx
	pop ecx
	pop ebx
	pop eax
	push ecx
	push edx
	push eax
	push ebx
	next

	defcode "2over",5,,2over
	mov eax,[esp+12]
	push eax
	mov eax,[esp+12]
	push eax
	next

	defcode "?dup",4,,qdup
	mov eax,[esp]
	test eax,eax
	jz .skip
	push eax
.skip:	next

	defcode "+",1,,add
	pop eax
	add [esp],eax
	next

	defcode "-",1,,sub
	pop eax
	sub [esp],eax
	next

	defcode "1+",2,,inc
	inc dword [esp]
	next

	defcode "1-",2,,dec
	dec dword [esp]
	next

	defcode "cell+",5,,celladd
	add dword [esp],4
	next

	defcode "cells",5,,cells
	shl dword [esp],2
	next

	defcode "*",1,,mul
	pop eax
	pop ebx
	imul eax,ebx
	push eax
	next

	defcode "/mod",4,,divmod
	xor edx,edx
	pop ebx
	pop eax
	idiv ebx
	push edx
	push eax
	next

	defcode "/",1,,div
	xor edx,edx
	pop ebx
	pop eax
	idiv ebx
	push eax
	next

	defcode "2*",2,,2mul
	shl dword [esp],1
	next

	defcode "2/",2,,2div
	sar dword [esp],1
	next

	defcode "abs",3,,abs
	pop eax
	mov ebx,eax
	neg eax
	cmovl eax,ebx
	push eax
	next

	defcode "min",3,,min
	pop ebx
	pop eax
	cmp eax,ebx
	cmovg eax,ebx
	push eax
	next

	defcode "max",3,,max
	pop ebx
	pop eax
	cmp eax,ebx
	cmovl eax,ebx
	push eax
	next

	defcode "lshift",6,,lshift	;( a n--b)
	pop ecx
	pop eax
	shl eax,cl
	push eax
	next

	defcode "rshift",6,,rshift	;( a n--b)
	pop ecx
	pop eax
	shr eax,cl
	push eax
	next



;******************************
;** comparison operators

;false is 0, true is <>0, default true is -1=0xffffffff

	defcode "=",1,,eq
	pop ebx
	pop ecx
	xor eax,eax
	cmp ecx,ebx
	sete al
	neg eax
	push eax
	next

	defcode "<>",2,,ne
	pop ebx
	pop ecx
	xor eax,eax
	cmp ecx,ebx
	setne al
	neg eax
	push eax
	next

	defcode "<",1,,lt
	pop ebx
	pop ecx
	xor eax,eax
	cmp ecx,ebx
	setl al
	neg eax
	push eax
	next

	defcode ">",1,,gt
	pop ebx
	pop ecx
	xor eax,eax
	cmp ecx,ebx
	setg al
	neg eax
	push eax
	next

	defcode "<=",2,,le
	pop ebx
	pop ecx
	xor eax,eax
	cmp ecx,ebx
	setle al
	neg eax
	push eax
	next

	defcode ">=",2,,ge
	pop ebx
	pop ecx
	xor eax,eax
	cmp ecx,ebx
	setge al
	neg eax
	push eax
	next

	defcode "0=",2,,0eq
	pop ecx
	xor eax,eax
	test ecx,ecx
	setz al
	neg eax
	push eax
	next

	defcode "0<>",3,,0ne
	pop ecx
	xor eax,eax
	test ecx,ecx
	setnz al
	neg eax
	push eax
	next

	defcode "0<",2,,0lt
	pop ecx
	xor eax,eax
	test ecx,ecx
	setl al
	neg eax
	push eax
	next

	defcode "0>",2,,0gt
	pop ecx
	xor eax,eax
	test ecx,ecx
	setg al
	neg eax
	push eax
	next

	defcode "and",3,,and
	pop eax
	and [esp],eax
	next

	defcode "or",2,,or
	pop eax
	or [esp],eax
	next

	defcode "xor",3,,xor
	pop eax
	xor [esp],eax
	next

	defcode "invert",6,,invert
	not dword [esp]
	next



;******************************
;** memory

	defcode "!",1,,store
	pop ebx
	pop eax
	mov [ebx],eax
	next

	defcode "@",1,,fetch
	pop ebx
	mov eax,[ebx]
	push eax
	next

	defcode "+!",2,,addstore
	pop ebx
	pop eax
	add [ebx],eax
	next

	defcode "c!",2,,storebyte
	pop ebx
	pop eax
	mov [ebx],al
	next

	defcode "c@",2,,fetchbyte
	pop ebx
	xor eax,eax
	mov al,[ebx]
	push eax
	next

	defcode "c@c!",4,,ccopy
	mov ebx,[esp+4]	;!!!benchmark with pop pop push push variant
	mov al,[ebx]
	pop edi
	stosb
	push edi
	inc dword [esp+4]
	next

	;bmove is fast but fails when end of src overlaps with dst !
	defcode "bmove",5,,bmove	;( src dst len--)
	mov edx,esi
	pop ecx
	pop edi
	pop esi
	rep movsb
	mov esi,edx
	next

	defcode "move",4,,move	;( src dst len--)
	mov edx,esi
	pop ecx
	pop edi
	pop esi
	cmp esi,edi
	jb .reverse
	rep movsb
	mov esi,edx
	next
.reverse:
	add esi,ecx
	dec esi
	add edi,ecx
	dec edi
	std
	rep movsb
	cld
	mov esi,edx
	next

	defcode "fill",4,,fill	;( adr len char--)
	pop eax
	pop ecx
	pop edi
	test ecx,ecx
	jz .skip
	rep stosb
.skip:
	next



;******************************
;** literals

	defcode "lit",3,,lit
	lodsd
	push eax
	next

	defcode "slit",4,,slit	;( --au)
	lodsd
	push esi	;addr
	push eax	;len
	add esi,eax
	add esi,1+3	;skip 0-terminator and align
	and esi,not 3
	next

	defcode "qs",2,f_immed,qs	;( --au)
	mov edi,[var_codehere]
	mov eax,wslit
	stosd
	push edi
	add edi,4
.skip:
	call _key
	cmp al,' '
	jbe .skip
	mov bl,al
	cmp al,'('
	je .bra
	or al,32	;'['=>'{'
	cmp al,'{'
	jne .first
	inc bl
.bra:
	inc bl
	jmp .first
.copy:
	stosb
.first:
	push ebx
	call _key
	pop ebx
	cmp al,bl
	jne .copy
	mov eax,edi
	pop ebx
	sub eax,ebx
	sub eax,4
	mov [ebx],eax	;store length
	xor eax,eax
	stosb		;0-terminated for winapi call
	add edi,3
	and edi,not 3
	mov [var_codehere],edi
	next


	defcode "compare",7,,compare	;( a1u1 a2u2-- -1|0|1)
	pop edx
	pop edi
	pop eax
	xchg esi,[esp]
	mov ecx,eax
	cmp eax,edx
	cmova ecx,edx
	xor ebx,ebx
	repe cmpsb
	pop esi
	jb .less
	ja .more
	cmp eax,edx
	ja .more
	je .end
.less:
        dec ebx
.end:
	push ebx
	next
.more:
	inc ebx
	push ebx
	next


	defcode "search",6,,search	;( a1u1 a2u2--a3u3 1 | a1u1 0)
	;search substring a2u2 in a1u1, a3=found position, u3=remaining length
	;edi+ecx=a1u1 esi+edx=a2u2
	mov edi,esi
	pop edx
	pop esi
	lodsb
	pop ecx
	xchg edi,[esp]
	push edi
	push ecx
	dec edx
	jz .onechar
.loop:
	repne scasb
	jne .nomatch
	cmp ecx,edx
	jb .nomatch
	push edi
	push esi
	push ecx
	mov ecx,edx
	repe cmpsb
	pop ecx
	pop esi
	pop edi
	jne .loop
.found:
        dec edi
        inc ecx
        add esp,8
        pop esi
        push edi
        push ecx
        push dword 1
	next
.onechar:
	repne scasb
	je .found
.nomatch:
	pop ecx
	pop eax
	pop esi
	push eax
	push ecx
	xor eax,eax
	push eax
	next



;******************************
;** built-in constants

macro defconst name,namelen,flags=0,label,value{
	defcode name,namelen,flags,label
	push value
	next
}

	defconst "r0",2,,r0,return_stack_top
	defconst "docol",5,,docol,docol
	defconst "create-code",11,,createcode,_create
	defconst "f_immed",7,,f_immed,f_immed
	defconst "f_hidden",8,,f_hidden,f_hidden
	defconst "f_lenmask",9,,f_lenmask,f_lenmask
	defconst "forth-wordlist",14,,forth_wid,forth_wid
	defconst "pad",3,,pad,numout_buffer
	defconst "cell",4,,cell,4
	defconst "0",1,,zero,0
	defconst "bl",2,,bl,32



;******************************
;** built-in variables

_create:
	push dword [eax+4]
	next
_does:
	push dword [eax+4]
	rpush esi
	mov esi,[eax+8]
	next
_value:
	mov eax,dword [eax+4]
	push dword [eax]
	next
_defer:
	mov eax,dword [eax+4]
	mov eax,[eax]
	next_eax
_to:
        dd $+4
        pop ecx
	lodsd
	mov [eax],ecx
	next
_addto:
        dd $+4
        pop ecx
	lodsd
	add [eax],ecx
	next

var_count=0
var_init equ

macro defvar name,namelen,flags=0,lbl,init=0{
	label var_ # lbl dword at variables+var_count*cell_size
	defcode name,namelen,flags,lbl
	push var_ # lbl
	next
	var_count = var_count + 1
	var_init equ var_init init,
}

	defvar "s0",2,,s0
	defvar "state",5,,state
	defvar "current",7,,current,forth_wid
	defvar "base",4,,base,10
	defvar "source-id",9,,sourceid,source_console



macro defvalue name,namelen,flags=0,lbl,init=0{
	label var_ # lbl dword at variables+var_count*cell_size
	defheader name,namelen,flags,lbl
	dd _value,var_ # lbl
	var_count = var_count + 1
	var_init equ var_init init,
}

	defvalue "code-here",9,,codehere,initial_code_here
	defvalue "here",4,,here,initial_here
	defvalue "stdin",5,,stdin,-1
	defvalue "stdout",6,,stdout,-1
	defvalue "tib",3,,tib,buffer
	defvalue "/tib",4,,endtib,buffer
	defvalue ">in",3,,toin,buffer
	defvalue "#pad",4,,npad,0



macro defdefer name,namelen,flags=0,lbl,init=0{
	label var_ # lbl dword at variables+var_count*cell_size
	defheader name,namelen,flags,lbl
	dd _defer,var_ # lbl
	var_count = var_count + 1
	var_init equ var_init init,
}

	defdefer "interpret",9,,interpret,winterpret1
	defdefer "refill",6,,refill,wrefill1



;******************************
;** stack

	defcode "exit",4,,exit
	rpop esi
	next

	defcode ">r",2,,tor
	pop eax
	rpush eax
	next

	defcode "r>",2,,rfrom
	rpop eax
	push eax
	next

	defcode "r@",2,,rfetch
	mov eax,[ebp]
	push eax
	next

	defcode "2>r",3,,2tor
	pop eax
	pop ecx
	rpush ecx
	rpush eax
	next

	defcode "2r>",3,,2rfrom
	rpop eax
	rpop ecx
	push ecx
	push eax
	next

	defcode "rsp@",4,,rspfetch
	push ebp
	next

	defcode "rsp!",4,,rspstore
	pop ebp
	next

	defcode "rdrop",5,,rdrop
	add ebp,4
	next

	defcode "dsp@",4,,dspfetch
	mov eax,esp
	push eax
	next

	defcode "dsp!",4,,dspstore
	pop esp
	next



;******************************
;** exceptions

	defcode "catch",5,,catch	;( xt--... 0|error)
	pop eax
_catch:
	lea ebp,[ebp-12]
	mov [ebp+8],esi
	mov ebx,[handler]
	mov [ebp+4],ebx
	mov [ebp],esp
	mov [handler],ebp
	mov esi,catch2
	next_eax

	align 4
catch2:
	dd $+4,$+4
	mov eax,[ebp+4]
	mov [handler],eax
	mov esi,[ebp+8]
	lea ebp,[ebp+12]
	xor eax,eax
	push eax
	next


	defcode "throw",5,,throw	;( ... 0|n--... |... n)
	pop eax
_throw:
	test eax,eax
	jz .success
	mov ebp,[handler]
	mov esp,[ebp]
	mov ebx,[ebp+4]
	mov [handler],ebx
	mov esi,[ebp+8]
	lea ebp,[ebp+12]
	push eax
.success:
	next



;******************************
;** input and output

source_string = -1
source_console = 0

	defcode "emit",4,,emit
	pop eax
	call _emit
	next

_emit:
	push eax
	mov eax,esp
	sub esp,4
	mov ecx,esp
	invoke WriteFile,[var_stdout],eax,1,ecx,0
	add esp,8
	ret


	defcode "type",4,,type	;( au--)
	pop ecx
	mov ebx,[esp]
	mov eax,esp
	invoke WriteFile,[var_stdout],ebx,ecx,eax,0
	pop eax
	next


	defcode "key",3,,key
	call _key
	push eax
	next

_key:
	mov ebx,[var_toin]
	cmp ebx,[var_endtib]
	jge .refill
	xor eax,eax
	mov al,[ebx]
	inc ebx		;nz after ret
	mov [var_toin],ebx
	ret
.refill:
	mov eax,[var_sourceid]
	cmp eax,source_string
	je .exit
	rpush esi
	mov esi,.done
	mov eax,wrefill
	next_eax
.done:
	dd $+4,$+4
	rpop esi
	pop eax
	test eax,eax	;z after ret if fail
	jnz _key
.exit:
	ret


	defcode "refill1",7,,refill1	;( --ok)
	mov eax,[var_tib]
	mov [var_toin],eax
	invoke ReadFile,[var_sourceid],eax,buffer_size,var_endtib,0
	test eax,eax
	jz .nosource	;eax=0
	mov eax,[var_endtib]
	test eax,eax
	jz .nosource2	;eax=0, !!todo: skip if GetFileType(h) returns pipe
	mov eax,[var_tib]
	add [var_endtib],eax	;[var_endtib]=count+start
	push eax	;<>0 - success
	next
.nosource:
	mov [var_endtib],eax
.nosource2:
	push eax	;=0 - fail
	next


	defcode "word",4,,word
	call _word
	push edi
	push ecx
	next

_word:	;out: edi,ecx,al=char after word
	call _key
	jz .nosource
	cmp al,' '
	jbe _word
	mov edi,word_buffer
	push esi
	mov esi,word_buffer_end-1
.store:
	stosb
	cmp edi,esi
	jae .skip
	call _key
	jz .stored
	cmp al,' '
	ja .store
.stored:
        xor ecx,ecx
        mov [edi],cl
	pop esi
	mov ecx,word_buffer
	sub edi,ecx	;z=0
	xchg edi,ecx	;ecx>0
	ret
.nosource:
	mov edi,word_buffer
	xor ecx,ecx	;z=1,ecx=0
	ret
.skip:
	call _key
	cmp al,' '
	ja .skip
	jmp .stored


	defcode "parse",5,,parse	;(char--adr u)
	pop ebx
	mov eax,parse_buffer_end-parse_buffer
	mov edi,parse_buffer
	jmp _parseto


	defcode "parse-to",8,,parseto	;( adr u1 char--adr u2)
	pop ebx
	pop eax
	pop edi
_parseto:
	push esi
	push edi
	mov esi,eax
	add esi,edi
	dec esi
.store:
        push ebx
        call _key
        pop ebx
	jz .stored
	cmp al,bl
	je .stored
	stosb
	cmp edi,esi
	jb .store
.skip:
        push ebx
	call _key
        pop ebx
	jz .stored
	cmp al,bl
	jne .skip
.stored:
        xor eax,eax
        mov [edi],al
        pop eax
        sub edi,eax
	pop esi
	push eax
	push edi
	next


	defcode "number",6,,number	;( au--n 0|n bad-count)
	pop ecx
	pop edi
	call _number
	push eax
	push ecx
	next

_number:
	xor eax,eax
	xor ebx,ebx
	test ecx,ecx
	jz .end
	mov edx,[var_base]
	mov bl,[edi]
	inc edi
	push eax	;0 for positive numbers
	cmp bl,'+'
	jz .first
	cmp bl,'-'
	jnz .char
	pop eax
	push ebx	;<>0 for negative numbers
	dec ecx
	jnz .first
	pop ebx
	mov ecx,1	;error: '-' without digits
	ret
.next:
	imul eax,edx
.first:
	mov bl,[edi]
	inc edi
.char:
	sub bl,'0'
	jb .negate
	cmp bl,10
	jb .index
	or bl,32	;change 'A'-'0' to 'a'-'0'
	sub bl,'a'-'0'
	jb .negate
	add bl,10
.index:
	cmp bl,dl	;digit >= base ?
	jge .negate
	add eax,ebx
	dec ecx
	jnz .next
.negate:
	pop ebx
	test ebx,ebx
	jz .end
	neg eax
.end:
	ret



;******************************
;** dictionary search

	defcode "find",4,,find	;( au--addr|0)
	pop ecx
	pop edi
	call _find
	push eax
	next

_find:
	mov ebx,[context]
.loop:
	mov edx,[ebx]
	call _search
	test eax,eax
	jnz .found
	sub ebx,4
	cmp ebx,order
	jnb .loop
.found:
	ret


_search:
	push esi
	;mov edx,[var_latest]
.record:
	test edx,edx
	jz .error
	xor eax,eax
	mov al,[edx+4]
	and al,f_hidden+f_lenmask	;hidden words appears as wrong length
	cmp al,cl
	jne .next
	push ecx
	push edi
	lea esi,[edx+5]
	repe cmpsb
	pop edi
	pop ecx
	jne .next
	pop esi
	mov eax,edx
	ret
.next:
	mov edx,[edx]
	jmp .record
.error:
	pop esi
	xor eax,eax
	ret


	defcode ">cfa",4,,tcfa	;( record--cfa)
	pop edi
	call _tcfa
	push edi
	next

_tcfa:
	xor eax,eax
	add edi,4
	mov al,[edi]
	inc edi
	and al,f_lenmask
	add edi,eax
	add edi,3
	and edi,not 3
	ret



;******************************
;** compiling

	defcode "header",6,,header	;( au--)
	pop ecx
	pop ebx
	mov edi,[var_codehere]
	mov eax,[var_current]
	mov eax,[eax]
	stosd
	mov al,cl
	stosb
	push esi
	mov esi,ebx
	rep movsb
	pop esi
	add edi,3
	and edi,not 3
	mov eax,[var_codehere]
	mov ebx,[var_current]
	mov [ebx],eax
	mov [var_codehere],edi
	next

	defcode "latest",6,,latest
	push [var_current]
	next

	defcode ",",1,,comma	;( n--)
	pop eax
	mov edi,[var_here]
	stosd
	mov [var_here],edi
	next

	defcode "w,",2,,wcomma	;( n--)
	pop eax
	mov edi,[var_here]
	stosw
	mov [var_here],edi
	next

	defcode "c,",2,,ccomma	;( c--)
	pop eax
	mov edi,[var_here]
	stosb
	mov [var_here],edi
	next


	defcode "compile",7,,compile	;( n--)
	pop eax
;	call _compile
	mov edi,[var_codehere]
	stosd
	mov [var_codehere],edi
	next

_compile:
	mov edi,[var_codehere]
	stosd
	mov [var_codehere],edi
	ret


	defcode "[",1,f_immed,lsbra
	xor eax,eax
	mov [var_state],eax
	next

	defcode "]",1,,rsbra
	mov [var_state],1
	next

	defword ":",1,,colon
	dd wword,wheader,wlit,docol,wcompile
	dd wlatest,wfetch,whidden,wrsbra,wexit

	defword ";",1,f_immed,semicolon
	dd wlit,wexit,wcompile
	dd wlatest,wfetch,whidden,wlsbra,wexit

	defcode "immediate",9,f_immed,immediate
	mov edi,[var_current]
	mov edi,[edi]
	add edi,4
	xor byte [edi],f_immed
	next

	defcode "hidden",6,,hidden	;( record--)
	pop edi
	add edi,4
	xor byte [edi],f_hidden
	next



;******************************
;** internal branching

	defcode "branch",6,,branch
_branch:
	add esi,[esi]
	next

	defcode "0branch",7,,zbranch
	pop eax
	test eax,eax
	jz _branch
	lodsd
	next


	defcode "loop",4,f_immed,loop
	mov eax,_loop2
_loop1:
	mov edi,[var_codehere]
	stosd
	pop eax
	sub eax,edi
	stosd
	mov [var_codehere],edi
	next
_loop2:
	dd $+4
	mov eax,[ebp]
	inc eax
	cmp eax,[ebp+4]
	jge .end
	mov [ebp],eax
	add esi,[esi]
	next
.end:
	lodsd
	add ebp,8
	next


	defcode "+loop",5,f_immed,addloop
	mov eax,.ploop1
	jmp _loop1
.ploop1:
	dd $+4
	mov eax,[ebp]
	mov ebx,eax
	pop ecx
	add ebx,ecx
	mov ecx,[ebp+4]
	cmp eax,ecx
	jge .agteq
;a<end:
	cmp ebx,ecx
	jge .end
.next:
	mov [ebp],ebx
	add esi,[esi]
	next
.agteq:
	cmp ebx,ecx
	jge .next
.end:
	lodsd
	add ebp,8
	next



;******************************
;** interpret

	defcode "interpret1",10,,interpret1
	rpush esi
.loop:
	call _word	;=edi,ecx
	test ecx,ecx
	jz .exit
	xor eax,eax
	mov [interpret_is_lit],eax
	call _find
	test eax,eax
	jz .trynum
	mov edi,eax	;record
	mov al,[edi+4]
	push ax
	call _tcfa
	pop ax
	and al,f_immed
	mov eax,edi
	jnz .execute
	jmp .use
.trynum:
	inc [interpret_is_lit]
	call _number
	test ecx,ecx
	jnz .error
	mov ebx,eax	;number
	mov eax,wlit
.use:
	mov edx,[var_state]
	test edx,edx
	jz .execute
	call _compile
	mov ecx,[interpret_is_lit]
	test ecx,ecx
	jz .loop
	mov eax,ebx
	call _compile
	jmp .loop
.execute:
	mov ecx,[interpret_is_lit]
	test ecx,ecx
	jnz .execlit
	mov esi,.ret
	next_eax	;execute, "next" will loop interpret
.execlit:
	push ebx
	jmp .loop
.exit:
	rpop esi
	next
.error:
	mov eax,-13	;undefined word
	jmp _throw

	align 4
.ret	dd $+4,.loop


	defword "error",5,,error
	dd wqdup,wzbranch,.end-$,wlit,.msg1,wlit,.msg2-.msg1,wtype
	dd wtoin,wlit,40,wsub,wtib,wmax,wtoin,wover,wsub,wtype
	dd wlit,.msg2,wlit,.msge-.msg2,wtype
.end	dd wexit
.msg1	db "Error in: ["
.msg2	db "]",13,10
.msge:


	defword "quit",4,,quit
.loop:
	dd wr0,wrspstore
	dd ws0,wfetch,wdspfetch,wsub,wlit,4,wdiv,wdot
	dd wslit,2,">   ",wtype
	dd wlit,winterpret,wcatch,werror
	dd wtib,_to,var_endtib,wbranch,.loop-$

;	defcode "quit",4,,quit
;	mov ebp,return_stack_top
;	mov esi,.interpret
;	next
;	align 4
;.interpret dd winterpret,wquit


	defcode "evaluate",8,,evaluate	;( au--)
	mov eax,[var_tib]	;!!! only for notfound msg
	rpush eax
	mov eax,[var_toin]
	rpush eax
	mov eax,[var_endtib]
	rpush eax
	mov eax,[var_sourceid]
	rpush eax
	pop ecx
	pop eax
	mov [var_tib],eax	;!!! only for notfound msg
	mov [var_toin],eax
	add eax,ecx
	mov [var_endtib],eax
	mov eax,source_string
	mov [var_sourceid],eax
	rpush esi
	mov esi,.done
	mov eax,winterpret
	jmp _catch

	align 4
.done	dd $+4,$+4
	rpop esi
	rpop eax
	mov [var_sourceid],eax
	rpop eax
	mov [var_endtib],eax
	rpop eax
	mov [var_toin],eax
	rpop eax
	mov [var_tib],eax	;!!! only for notfound msg
	pop eax
	jmp _throw



;******************************
;** os basic tools

	defcode "LoadLibrary",11,,loadlib	;( file--h)
	call [LoadLibrary]
	push eax
	next

	defcode "GetProcAddress",14,,getprocaddress	;???( name hmodule--addr)
	call [GetProcAddress]
	push eax
	next

	defcode "stdcall",7,,stdcall	;( addr--ret)
	pop eax
	call eax
	push eax
	next

	defconst "r/o",3,,filero,0x80000000
	defconst "w/o",3,,filewo,0x40000000
	defconst "r/w",3,,filerw,0xC0000000


	defcode "create-file",11,,createfile	;( a u mode--h err?)
	mov edx,2	;create_always
create_common:
	pop eax
	pop ecx
	and ecx,1023	;buffer overflow guard (winapi max_path is 260!)
	xchg esi,[esp]
	mov edi,syspad
	rep movsb
	pop esi
	mov [edi],cl	;cl=0
	;file_share_read=1, file_attribute_normal=128
	invoke CreateFile,syspad,eax,1,0,edx,128,0
	push eax
zeroerr:
	xor ecx,ecx
	test eax,eax
	mov eax,-1
	cmovnz eax,ecx
	push eax
	next


	defcode "open-file",9,,openfile	;( a u mode--h err?)
	mov edx,3	;open_existing
	jmp create_common


	defcode "close-file",10,,closefile	;( h--err?)
	pop eax
	invoke CloseHandle,eax
	jmp zeroerr


	defcode "read-file",9,,readfile	;( a u h--n err?)
	pop eax
	pop ecx
	mov edx,esp	;[edx]=a => [edx]=[esp]=n
	invoke ReadFile,eax,[edx],ecx,edx,0
	jmp zeroerr


	defcode "write-file",10,,writefile	;( a u h--err?)
	pop eax
	pop ecx
	mov edx,esp	;[edx]=a => [edx]=[esp]=n
	invoke WriteFile,eax,[edx],ecx,edx,0
	pop ecx
	jmp zeroerr



;******************************
;** ****** high level definitions

;******************************
;** misc

	defcode "execute",7,,execute
	pop eax
	next_eax

	defcode "bye",3,,bye
	jmp exitapp

	defcode "char",4,,char
	call _word
	xor eax,eax
	mov al,[edi]
	push eax
	next

	defword "mod",3,,mod
	dd wdivmod,wdrop,wexit

	defword "'",1,,tick
	dd wword,wfind,wtcfa,wexit

	defword "postpone",8,f_immed,postpone
	dd wword,wfind,wdup,wcelladd,wfetchbyte
	dd wf_immed,wand,wzbranch,.nonimm-$,wtcfa,wcompile,wexit
.nonimm	dd wtcfa,wlit,wlit,wcompile,wcompile,wlit,wcompile,wcompile,wexit

	defword "literal",7,f_immed,literal	;( n--)
	dd wlit,wlit,wcompile,wcompile,wexit

	defword "(",1,f_immed,lbra	;skip nested comments ( ( ))
	dd wlit,1
.loop	dd wkey,wdup,wlit,40,weq,wzbranch,.check2-$
	dd wdrop,winc,wbranch,.loop-$
.check2	dd wlit,41,weq,wzbranch,8,wdec,wdup,w0eq,wzbranch,.loop-$,wdrop,wexit

	defword "recurse",7,f_immed,recurse
	dd wlatest,wfetch,wtcfa,wcompile,wexit



;******************************
;** create

	defword "to",2,f_immed,to
	dd wword,wfind,wtcfa,wcelladd,wfetch,wstate,wfetch,wzbranch,.else-$
	dd wlit,_to,wcompile,wcompile,wexit
.else	dd wstore,wexit

	defword "+to",3,f_immed,addto
	dd wword,wfind,wtcfa,wcelladd,wfetch,wstate,wfetch,wzbranch,.else-$
	dd wlit,_addto,wcompile,wcompile,wexit
.else	dd waddstore,wexit

	defword "aligned",7,,aligned
	dd wlit,3,wadd,wlit,0xffffffff-3,wand,wexit

	defword "align",5,,align
	dd where,waligned,_to,var_here,wexit

	defword "value",5,,value
	dd walign,wword,wheader,wlit,_value,wcompile
	dd where,wdup,wcompile,wdup,wcelladd,_to,var_here,wstore,wexit

	defword "defer",5,,defer
	dd walign,wword,wheader,wlit,_defer,wcompile
	dd where,wdup,wcompile,wcelladd,_to,var_here,wexit

	defword "allot",5,,allot
	dd where,wadd,_to,var_here,wexit

	defword "create",6,,create
	dd walign,wword,wheader,wcreatecode,wcompile
	dd where,wcompile,wexit

	defword "does>",5,,does
	dd wrfrom,wcompile
	dd wlit,_does,wcodehere,wlit,3*cell_size,wsub,wstore,wexit

	defword "constant",8,,constant
	dd wword,wheader,wcreatecode,wcompile,wcompile,wexit

	defword "variable",8,,variable
	dd walign,wword,wheader,wcreatecode,wcompile
	dd where,wdup,wcompile,wcelladd,_to,var_here,wexit



;******************************
;** branching

	defword "if",2,f_immed,if
	dd wlit,wzbranch,wcompile,wcodehere,wzero,wcompile,wexit

	defword "then",4,f_immed,then
	dd wcodehere,wover,wsub,wswap,wstore,wexit

	defword "else",4,f_immed,else
	dd wlit,wbranch,wcompile,wcodehere,wzero,wcompile
	dd wswap,wcodehere,wover,wsub,wswap,wstore,wexit

	defword "begin",5,f_immed,begin
	dd wcodehere,wexit

	defword "until",5,f_immed,until
	dd wlit,wzbranch,wcompile,wcodehere,wsub,wcompile,wexit

	defword "again",5,f_immed,again
	dd wlit,wbranch,wcompile,wcodehere,wsub,wcompile,wexit

	defword "while",5,f_immed,while
	dd wlit,wzbranch,wcompile,wcodehere,wzero,wcompile,wexit

	defword "repeat",6,f_immed,repeat
	dd wlit,wbranch,wcompile,wcodehere,wrot,wover,wsub,wcompile
	dd wcelladd,wover,wsub,wswap,wstore,wexit

	defword "do",2,f_immed,do
	dd wlit,w2tor,wcompile,wcodehere,wexit

	defword "i",1,f_immed,i
	dd wlit,wrfetch,wcompile,wexit



;******************************
;** wordlists

	defword "wordlist",8,,wordlist	;( --wid)
	dd walign,where,wzero,wcomma,wexit

	defword "also",4,,also	;( wid--)
	dd wlit,context,wdup,wfetch,wcelladd,wtuck,wswap,wstore,wstore,wexit

	defword "previous",8,,previous
	dd wlit,-cell_size,wlit,context,waddstore,wexit

	defword "definitions",11,,definitions
	dd wlit,context,wfetch,wfetch,wcurrent,wstore,wexit

	defword "only",4,,only	;( wid--)
	dd wlit,order,wdup,wlit,context,wstore,wstore,wexit

;	defword "context",7,,context	;( --order+n)
;	dd wlit,context,wfetch,wexit



;******************************
;** numeric output

	defword "decimal",7,,decimal
	dd wlit,10,wbase,wstore,wexit

	defword "hex",7,,hex
	dd wlit,16,wbase,wstore,wexit

	defword "<#",2,,numbeg  ;( n--)
	dd wzero,wlit,numout_buffer_end-1
	dd wdup,wlit,numpos,wstore,wstorebyte,wexit

	defword "hexchar",7,,hexchar  ;( n--char)
	dd wdup,wlit,9,wgt,wzbranch,.digit-$,wlit,65-10,wadd,wexit
.digit	dd wlit,48,wadd,wexit

	defword "#",1,,digit  ;( n1--n2) !!!buffer overflow guard?
	dd wbase,wfetch,wdivmod,wswap,whexchar,wlit,numpos,wdup,wfetch
	dd wdec,wdup,wrot,wstore,wstorebyte,wexit

	defword "#s",2,,digits  ;( n1--n2)
	dd wdigit,wdup,w0eq,wzbranch,-16,wexit

	defword "#>",2,,numend  ;( n--au)
	dd wdrop,wlit,numpos,wfetch,wlit,numout_buffer_end-1,wover,wsub,wexit

	defword "sign",4,,sign  ;( n--)
	dd w0lt,wzbranch,.skip-$,wlit,numpos,wfetch,wdec
	dd wlit,45,wover,wstorebyte,_to,numpos
.skip	dd wexit

	defword "hold",4,,hold  ;( char--)
	dd wlit,numpos,wfetch,wdec,wdup,_to,numpos,wstorebyte,wexit

	defword "holds",5,,holds  ;( au--)
	dd wlit,numpos,wfetch,wover,wsub,wdup,_to,numpos
	dd wswap,wbmove,wexit

	defword ".",1,,dot
	dd wnumbeg,wdup,wabs,wdigits,wswap,wsign,wnumend,wtype,wexit



;******************************
;** pad strings

	defword ">pad",4,,topad	;( au--)
	dd wdup,_to,var_npad,wpad,wswap,wbmove,wexit

	defword "+pad",4,,addpad	;( au--)
	dd wnpad,w2dup,wadd,_to,var_npad,wpad,wadd,wswap,wbmove,wexit



last_record = link



;******************************
;** .data

section '.data' data readable writeable


data import
 ;import data in the same section
 library kernel,'KERNEL32.DLL'
 import kernel,\
	GetStdHandle,'GetStdHandle',\
	CloseHandle,'CloseHandle',\
	CreateFile,'CreateFileA',\
	ExitProcess,'ExitProcess',\
	GetLastError,'GetLastError',\
	GetModuleHandle,'GetModuleHandleA',\
	GetProcAddress,'GetProcAddress',\
	LoadLibrary,'LoadLibraryA',\
	ReadFile,'ReadFile',\
	SetFilePointer,'SetFilePointer',\
	VirtualAlloc,'VirtualAlloc',\
	VirtualFree,'VirtualFree',\
TlsAlloc,'TlsAlloc',\
TlsGetValue,'TlsGetValue',\
	WriteFile,'WriteFile'
end data


data export
;  export 'fim.exe',\
;	WindowProc,'WindowProc',\
;	tolog,'tolog',\
;	create_window,'create_window',\
;	readdir,'readdir'
end data


source_str:
	file "forth.src"
source_stre:

	rb 64	;space to prevent cache line invalidation
	align 4
order	dd forth_wid,15 dup ?
context	dd order
forth_wid dd last_record
handler	dd 0

	var_init equ var_init 0	;!!!todo: remove final ,0
variables:
	dd var_init
;        match params, var_init { dd params }

initial_here:
	rb 65536



;******************************

section '.bss' readable writeable

	rb 4096
return_stack_top:

buffer_size = 4096
buffer	rb buffer_size
buffer_end:

numout_buffer rb 1024
numout_buffer_end:
parse_buffer rb 1024
parse_buffer_end:
syspad rb 1024+4
syspad_end:
word_buffer rb 32	;31+1 for \0
word_buffer_end:

	align 4
interpret_is_lit dd ?
numpos	dd ?

	rb 64	;space to prevent cache line invalidation

initial_code_here:
	rb 65536
