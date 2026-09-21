[BITS 32]

section .rodata use32

	white_space db 9,10,11,12,13,32,0
	digit db "0123456789",0
	
	range_lower db 'a','z'
	range_upper db 'A','Z'
	
section .text use32

	global ctype_isSpace	;int ctype_isSpace(int c)
	global ctype_isDigit	;int ctype_isDigit(int c)
	global ctype_isLower	;int ctype_isLower(int c)
	global ctype_isUpper	;int ctype_isUpper(int c)
	global ctype_isAlpha	;int ctype_isAlpha(int c)
	global ctype_isAlnum	;int ctype_isAlnum(int c)
	global ctype_isSpaceOrZero	;int ctype_isSpaceOrZero(int c)
	
ctype_isSpace:
	mov eax, dword[esp+4]
	push white_space
	push eax
	call ctype_isInString_internal
	add esp, 8
	ret
	
ctype_isDigit:
	mov eax, dword[esp+4]
	push digit
	push eax
	call ctype_isInString_internal
	add esp, 8
	ret
	
ctype_isLower:
	mov eax, dword[esp+4]
	push range_lower
	push eax
	call ctype_isInRange_internal
	add esp, 8
	ret
	
ctype_isUpper:
	mov eax, dword[esp+4]
	push range_upper
	push eax
	call ctype_isInRange_internal
	add esp, 8
	ret
	
ctype_isAlpha:
	push ebp
	mov ebp, esp
	
	push 0
	
	push dword[ebp+8]
	call ctype_isLower
	or dword[ebp-4], eax
	call ctype_isUpper
	or dword[ebp-4], eax
	
	ctype_isAlpha_end:
	mov eax, dword[ebp-4]
	
	mov esp, ebp
	pop ebp
	ret
	
ctype_isAlnum:
	push ebp
	mov ebp, esp
	
	push 0
	
	push dword[ebp+8]
	call ctype_isAlpha
	or dword[ebp-4], eax
	call ctype_isDigit
	or dword[ebp-4], eax
	
	ctype_isAlnum_end:
	mov eax, dword[ebp-4]
	
	mov esp, ebp
	pop ebp
	ret
	
	
ctype_isSpaceOrZero:
	mov eax, 67
	test byte[esp+4], 0xff
	jz ctype_isSpaceOrZero_end
	mov ecx, dword[esp+4]
	push ecx
	call ctype_isSpace
	add esp, 4
	ctype_isSpaceOrZero_end:
	ret
	

;internal functinos

;int ctype_isInString_internal(int, const char*)
ctype_isInString_internal:
	mov ecx, dword[esp+4]
	mov edx, dword[esp+8]
	
	xor eax, eax
	dec edx
	ctype_isInString_internal_loop_start:
		inc edx
		test byte[edx], 0xff
		jz ctype_isInString_internal_end
		cmp cl, byte[edx]
		jne ctype_isInString_internal_loop_start
		
	mov eax, 67
	
	ctype_isInString_internal_end:
	ret
	

;int ctype_isInRange_internal(int, char rangeInclusive[2])
ctype_isInRange_internal:
	xor eax, eax
	mov ecx, dword[esp+4]
	mov edx, dword[esp+8]
	cmp cl, byte[edx]
	jl ctype_isInRange_internal_end
	cmp cl, byte[edx+1]
	jg ctype_isInRange_internal_end
	mov eax, 67
	ctype_isInRange_internal_end:
	ret