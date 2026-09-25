[BITS 32]

section .rodata use32
	PRINTF_FLOAT_PRECISION equ 3
	
	format_string db "%s",0
	format_char db "%c",0
	format_signed_int db "%d",0
	format_float db "%f",0
	
	insert_handlers:	;int insert_handler(char* buffer, void* addrInsertee), returns the number of new characters in the buffer
		;handler, format string length, format string address, insertee length
		dd sprintf_insertString_internal, 2, format_string, 4
		dd sprintf_insertChar_internal, 2, format_char, 4		;note that a char is also 4 bytes in the argument list
		dd sprintf_insertSignedInt_internal, 2, format_signed_int, 4
		dd sprintf_insertFloat_internal, 2, format_float, 4
		dd 0
		
	read_handlers:		;int read_handler(char* buffer, void* addrReadee), returns the number of read characters in the buffer, -1 if a problem occured
		;handler, format string length, format string address, readee length
		dd sscanf_readString_internal, 2, format_string, 4
		dd sscanf_readChar_internal, 2, format_char, 4
		dd sscanf_readSignedInt_internal, 2, format_signed_int, 4
		dd sscanf_readFloat_internal, 2, format_float, 4
		dd 0
	
	P10 dd 0.1

section .text use32

	extern memcmp
	
	extern ctype_isDigit
	extern ctype_isSpaceOrZero
	
	extern console_bookmark

	global strlen		;int strlen(const char* string)
	global sprintf		;int sprintf(char* buffer, const char* format, ...)
	global sscanf		;int sscanf(const char* buffer, const char* format, ...)

	strlen:
		mov ecx, dword[esp+4]
		xor eax, eax
		strlen_loop_start:
			test byte[ecx], 0xff
			jz strlen_loop_end
			inc eax
			inc ecx
			jmp strlen_loop_start
		strlen_loop_end:
		ret
		

	sprintf:
		push ebp
		push esi
		push edi
		push ebx
		mov ebp, esp
		
		sub esp, 4		;next argument offset
		
		mov dword[ebp-4], 8
		
		mov esi, dword[ebp+24]
		mov edi, dword[ebp+20]
		sprintf_loop_start:
			cmp byte[esi], '%'
			je sprintf_loop_insert
				cld
				movsb
				jmp sprintf_loop_continue
				
			sprintf_loop_insert:
				mov ebx, insert_handlers
				sprintf_loop_insert_loop_start:
					;check if the format stimmt
					push dword[ebx+4]
					push dword[ebx+8]
					push esi
					call memcmp
					add esp, 12
					test eax, eax
					jnz sprintf_loop_insert_loop_continue
					
					;call the handler
					mov eax, dword[ebp-4]
					lea eax, [ebp+20+eax]
					push eax
					push edi
					call dword[ebx]
					add esp, 8
					
					;adjust the offsets
					add edi, eax
					add esi, dword[ebx+4]
					mov ecx, dword[ebx+12]
					add dword[ebp-4], ecx
					
					jmp sprintf_loop_insert_loop_end
					
					sprintf_loop_insert_loop_continue:
					add ebx, 16
					test dword[ebx], 0xffffffff
					jnz sprintf_loop_insert_loop_start
					;invalid format
				sprintf_loop_insert_loop_end:
		
			sprintf_loop_continue:
			test byte[esi], 0xff
			jnz sprintf_loop_start
			mov byte[edi], 0
		sprintf_loop_end:
		
		;set retun value
		push dword[ebp+20]
		call strlen
		add esp, 4
		
		mov esp, ebp
		pop ebx
		pop edi
		pop esi
		pop ebp
		ret


sscanf:
	push ebp
	push esi
	push edi
	push ebx
	mov ebp, esp
	
	sub esp, 4			;args read					4
	sub esp, 4			;next arg offset from ebp	8
	
	mov dword[ebp-4], 0
	mov dword[ebp-8], 28
	
	mov esi, dword[ebp+20]		;buffer
	mov edi, dword[ebp+24]		;format
	sscanf_loop_start:
		;check if either of the strings is finished
		test byte[esi], 0xff
		jz sscanf_loop_end
		test byte[edi], 0xff
		jz sscanf_loop_end
		;check if a special sequence comes
		cmp byte[edi], '%'
		jne sscanf_loop_not_special
			mov ebx, read_handlers
			sscanf_loop_read_loop_start:
				;handlers are done?
				test dword[ebx], 0xffffffff
				jz sscanf_loop_end
				
				;check if the special string is this one
				push dword[ebx+4]
				push dword[ebx+8]
				push edi
				call memcmp
				add esp, 12
				
				test eax, eax
				jnz sscanf_loop_read_loop_continue
					;do the handling
					mov eax, dword[ebp-8]
					add eax, ebp
					
					push eax
					push esi
					call dword[ebx]
					add esp, 8
					
					cmp eax, -1
					je sscanf_loop_end
					
					inc dword[ebp-4]
					mov ecx, dword[ebx+12]
					add dword[ebp-8], ecx
					
					add esi, eax
					add edi, dword[ebx+4]
					jmp sscanf_loop_continue		;jump to outer loop
					
				sscanf_loop_read_loop_continue:
				add ebx, 16
				jmp sscanf_loop_read_loop_start
		sscanf_loop_not_special:
			;check if the next characters match
			cld
			cmpsb
			jne sscanf_loop_end
			
		sscanf_loop_continue:
		jmp sscanf_loop_start
	sscanf_loop_end:
	
	mov eax, dword[ebp-4]
	
	mov esp, ebp
	pop ebx
	pop edi
	pop esi
	pop ebp
	ret

		
;internal functions
		
	sprintf_insertString_internal:
		push ebp
		push esi
		push edi
		mov ebp, esp
		
		sub esp, 4		;length of string
		
		mov eax, dword[ebp+20]
		push dword[eax]
		call strlen
		mov dword[ebp-4], eax
		add esp, 4
		
		test dword[ebp-4], 0xffffffff
		jz sprintf_insertString_internal_end
		
		mov ecx, dword[ebp-4]
		mov esi, dword[ebp+20]
		mov esi, dword[esi]
		mov edi, dword[ebp+16]
		cld
		sprintf_insertString_internal_loop_start:
			movsb
			dec ecx
			jnz sprintf_insertString_internal_loop_start
		
		sprintf_insertString_internal_end:
		mov eax, dword[ebp-4]
		
		mov esp, ebp
		pop edi
		pop esi
		pop ebp
		ret
		
		
sprintf_insertChar_internal:
	mov edx, dword[esp+4]
	mov ecx, dword[esp+8]
	mov ecx, dword[ecx]
	mov byte[edx], cl
	
	mov eax, 1

	ret
	
		
sprintf_insertSignedInt_internal:
	push ebp
	push esi
	push edi
	push ebx
	mov ebp, esp
	
	sub esp, 4		;length
	sub esp, 4		;printee
	sub esp, 4		;number of numerical characters
	
	mov dword[ebp-4], 0
	mov dword[ebp-12], 0
	
	
	mov eax, dword[ebp+24]
	mov eax, dword[eax]
	mov dword[ebp-8], eax
	
	;is the number int_min?
	cmp dword[ebp-8], 0x80000000
	jne sprintf_insertSignedInt_internal_skip_int_min
		push sprintf_insertSignedInt_internal_int_min_text
		push sprintf_insertSignedInt_internal_print_string
		push dword[ebp+20]
		call sprintf
		mov dword[ebp-4], eax
		jmp sprintf_insertSignedInt_internal_end
		
	sprintf_insertSignedInt_internal_skip_int_min:
	
	;is the number negative?
	test dword[ebp-8], 0x80000000
	jz sprintf_insertSignedInt_internal_skip_negative
		mov eax, dword[ebp+20]
		mov byte[eax], '-'
		inc dword[ebp+20]
		inc dword[ebp-4]
		neg dword[ebp-8]
	sprintf_insertSignedInt_internal_skip_negative:
	
	;start to print
	mov eax, dword[ebp-8]
	mov ecx, 10
	mov ebx, dword[ebp+20]
	sprintf_insertSignedInt_internal_loop_start:
		xor edx, edx
		idiv ecx
		
		add dl, '0'
		mov byte[ebx], dl
		inc ebx
	
		inc dword[ebp-4]
		inc dword[ebp-12]
	
		test eax, eax
		jnz sprintf_insertSignedInt_internal_loop_start
		
	;flip the numbers, because now the number with the lowest alaki ertek is the first
	mov esi, dword[ebp+20]
	mov edi, dword[ebp-12]
	lea edi, [edi+esi-1]
	mov ebx, dword[ebp-12]
	shr ebx, 1
	test ebx, ebx
	jz sprintf_insertSignedInt_internal_flip_loop_end
	sprintf_insertSignedInt_internal_flip_loop_start:
		mov al, byte[esi]
		mov cl, byte[edi]
		mov byte[esi], cl
		mov byte[edi], al
		inc esi
		dec edi
		
		dec ebx
		jnz sprintf_insertSignedInt_internal_flip_loop_start
	
	sprintf_insertSignedInt_internal_flip_loop_end:
	
	sprintf_insertSignedInt_internal_end:
	mov eax, dword[ebp-4]
	
	mov esp, ebp
	pop ebx
	pop edi
	pop esi
	pop ebp
	ret
	sprintf_insertSignedInt_internal_print_string db "%s",0
	sprintf_insertSignedInt_internal_int_min_text db "-2147483648",0
	
	
sprintf_insertFloat_internal:
	push ebp
	push esi
	push edi
	push ebx
	mov ebp, esp
	
	sub esp, 4		;multiplier for the sussy
	sub esp, 4		;number
	sub esp, 4		;printed characters
	sub esp, 4		;helper character counter
	sub esp, 4		;helper

	mov dword[ebp-12], 0
	mov dword[ebp-16], 0
	
	mov eax, dword[ebp+24]
	mov eax, dword[eax]
	mov dword[ebp-8], eax
	
	;calculate the display precision
	mov eax, PRINTF_FLOAT_PRECISION
	mov ecx, 1
	cmp eax, 0
	jle sprintf_insertFloat_internal_precision_loop_end
	sprintf_insertFloat_internal_precision_loop_start:
		imul ecx, 10
		dec eax
		jnz sprintf_insertFloat_internal_precision_loop_start
	sprintf_insertFloat_internal_precision_loop_end:
	cvtsi2ss xmm0, ecx
	movss dword[ebp-4], xmm0
	
	;check if niggative
	test dword[ebp-8], 0x80000000
	jz sprintf_insertFloat_internal_skip_negative
		mov eax, dword[ebp+20]
		mov byte[eax], '-'
		inc dword[ebp+20]
		and dword[ebp-8], 0x7fffffff
		
		inc dword[ebp-12]
	sprintf_insertFloat_internal_skip_negative:
	
	;print the whole part
	mov dword[ebp-16], 0
	mov edi, dword[ebp+20]
	movss xmm0, dword[ebp-8]
	roundss xmm0, xmm0, 0b0001
	cvtss2si eax, xmm0
	sprintf_insertFlat_internal_whole_loop_start:
		xor edx, edx
		mov ecx, 10
		idiv ecx
		
		add dl, '0'
		mov byte[edi], dl
		inc edi
		inc dword[ebp-12]
		inc dword[ebp-16]
		
		test eax, eax
		jnz sprintf_insertFlat_internal_whole_loop_start
		
	mov dword[ebp+20], edi
	
	
	;flip the whole part
	mov esi, edi
	sub esi, dword[ebp-16]
	dec edi
	mov ebx, dword[ebp-16]
	shr ebx, 1
	test ebx, ebx
	jz sprintf_insertFlat_internal_whole_flip_loop_end
	sprintf_insertFlat_internal_whole_flip_loop_start:
		mov al, byte[esi]
		mov cl, byte[edi]
		mov byte[esi], cl
		mov byte[edi], al
		inc esi
		dec edi
		dec ebx
		jnz sprintf_insertFlat_internal_whole_flip_loop_start
	sprintf_insertFlat_internal_whole_flip_loop_end:
	
	;print the comma
	mov eax, dword[ebp+20]
	mov byte[eax], ','
	inc dword[ebp+20]
	inc dword[ebp-12]
	
	;print the fraction part
	movss xmm0, dword[ebp-8]
	movss xmm1, dword[ebp-4]
	mulss xmm0, xmm1
	roundss xmm0, xmm0, 0
	cvtss2si eax, xmm0
	mov dword[ebp-20], eax
	
	mov dword[ebp-16], 0
	mov ebx, PRINTF_FLOAT_PRECISION
	mov eax, dword[ebp-20]
	mov edi, dword[ebp+20]
	cmp ebx, 0
	jle sprintf_insertFlat_internal_fraction_loop_end
	sprintf_insertFlat_internal_fraction_loop_start:
		xor edx, edx
		mov ecx, 10
		idiv ecx
		add dl, '0'
		
		mov byte[edi], dl
		
		inc edi
		inc dword[ebp-12]
		inc dword[ebp-16]
		
		dec ebx
		jnz sprintf_insertFlat_internal_fraction_loop_start
		
	sprintf_insertFlat_internal_fraction_loop_end:
	
	;flip the fraction part
	mov esi, dword[ebp+20]
	mov edi, dword[ebp-16]
	lea edi, [esi+edi-1]
	mov ebx, dword[ebp-16]
	shr ebx, 1
	test ebx, ebx
	jz sprintf_insertFlat_internal_fraction_flip_loop_end
	sprintf_insertFlat_internal_fraction_flip_loop_start:
		mov al, byte[esi]
		mov cl, byte[edi]
		mov byte[esi], cl
		mov byte[edi], al
		inc esi
		dec edi
		dec ebx
		jnz sprintf_insertFlat_internal_fraction_flip_loop_start
	sprintf_insertFlat_internal_fraction_flip_loop_end:
	
	sprintf_insertFlat_internal_end:
	mov eax, dword[ebp-12]
	
	mov esp, ebp
	pop ebx
	pop edi
	pop esi
	pop ebp
	ret
	
;int func(char*, char**)	
sscanf_readString_internal:
	push ebp
	push esi
	push edi
	push ebx
	mov ebp, esp
	
	sub esp, 4		;chars read		4
	
	mov dword[ebp-4], 0
	
	mov esi, dword[ebp+20]
	mov edi, dword[ebp+24]
	mov edi, dword[edi]
	sscanf_readString_internal_loop_start:
		movzx eax, byte[esi]
		push eax
		call ctype_isSpaceOrZero
		add esp, 4
		test eax, eax
		jnz sscanf_readString_internal_loop_end
		
		movsb
		inc dword[ebp-4]
		jmp sscanf_readString_internal_loop_start
		
	sscanf_readString_internal_loop_end:
	
	mov byte[edi], 0		;close the string
	
	mov eax, dword[ebp-4]
	
	mov esp, ebp
	pop ebx
	pop edi
	pop esi
	pop ebp
	ret
	

;int func(char*, char**)
sscanf_readChar_internal:
	push ebp
	mov ebp, esp
	
	sub esp, 4		;read coutn
	
	mov dword[ebp-4], -1
	
	mov eax, dword[ebp+8]
	test byte[eax], 0xff
	jz sscanf_readChar_internal_end
	
	mov ecx, dword[ebp+12]
	mov ecx, dword[ecx]
	mov dl, byte[eax]
	mov byte[ecx], dl
	
	mov dword[ebp-4], 1
	
	sscanf_readChar_internal_end:
	mov eax, dword[ebp-4]
	
	mov esp, ebp
	pop ebp
	ret
	
	
;int func(char*, int**)
sscanf_readSignedInt_internal:
	push ebp
	push esi
	push edi
	push ebx
	mov ebp, esp
	
	sub esp, 4		;is negative		4
	sub esp, 4		;number abs			8
	sub esp, 4		;chars read			12
	
	mov dword[ebp-4], 0
	mov dword[ebp-8], 0
	mov dword[ebp-12], 0
	
	mov esi, dword[ebp+20]
	sscanf_readSignedInt_internal_loop_start:
		cmp byte[esi], '-'
		jne sscanf_readSingedInt_internal_loop_not_minus
			test dword[ebp-12], 0xffffffff
			jnz sscanf_readSignedInt_internal_loop_end
			mov dword[ebp-4], 67
			jmp sscanf_readSignedInt_internal_loop_continue
		sscanf_readSingedInt_internal_loop_not_minus:
		
		movzx eax, byte[esi]
		push eax
		call ctype_isDigit
		pop ecx
		test eax, eax
		jz sscanf_readSignedInt_internal_loop_end
		
		sub ecx, '0'
		mov edx, dword[ebp-8]
		imul edx, 10
		add edx, ecx
		mov dword[ebp-8], edx
		
		sscanf_readSignedInt_internal_loop_continue:
		inc dword[ebp-12]
		inc esi
		jmp sscanf_readSignedInt_internal_loop_start
	sscanf_readSignedInt_internal_loop_end:

	;check if the read was successful
	test dword[ebp-12], 0xffffffff
	jnz sscanf_readSignedInt_internal_success
		mov dword[ebp-12], -1
		jmp sscanf_readSignedInt_internal_end
	sscanf_readSignedInt_internal_success:
	
	;write the number
	mov ecx, dword[ebp-8]
	test dword[ebp-4], 0xffffffff
	jz sscanf_readSingedInt_internal_not_negative
		neg ecx
	sscanf_readSingedInt_internal_not_negative:
	
	mov edx, dword[ebp+24]
	mov edx, dword[edx]
	mov dword[edx], ecx
	
	sscanf_readSignedInt_internal_end:
	mov eax, dword[ebp-12]
	
	mov esp, ebp
	pop ebx
	pop edi
	pop esi
	pop ebp
	ret
	
	
;int sscanf_readFloat_internal(char* buffer, float** pp)
sscanf_readFloat_internal:
	push ebp
	push esi
	push edi
	push ebx
	mov ebp, esp
	
	sub esp, 4		;chars read				4
	sub esp, 4		;whole chars read		8
	sub esp, 4		;fractional chars read	12
	
	sub esp, 4		;whole part as int		16
	sub esp, 4		;fractional part as int	20
	
	sub esp, 4		;sign read				24
	sub esp, 4		;decimal point read		28
	
	mov dword[ebp-4], 0
	mov dword[ebp-8], 0
	mov dword[ebp-12], 0
	mov dword[ebp-16], 0
	mov dword[ebp-20], 0
	mov dword[ebp-24], 0
	mov dword[ebp-28], 0
	
	mov esi, dword[ebp+20]
	sscanf_readFloat_internal_loop_start:
		;minus sign
		cmp byte[esi], '-'
		jne sscanf_readFloat_internal_loop_not_minus
			test dword[ebp-4], 0xffffffff
			jnz sscanf_readFloat_internal_loop_end
			mov dword[ebp-24], 0x80000000				;this is a mask, the number matters
			jmp sscanf_readFloat_internal_loop_continue
		sscanf_readFloat_internal_loop_not_minus:
		
		;decimal point
		cmp byte[esi], '.'
		jne sscanf_readFloat_internal_loop_not_point
			test dword[ebp-28], 0xffffffff
			jnz sscanf_readFloat_internal_loop_end
			mov dword[ebp-28], 67
			jmp sscanf_readFloat_internal_loop_continue
		sscanf_readFloat_internal_loop_not_point:
		
		;digit
		movzx eax, byte[esi]
		push eax
		call ctype_isDigit
		add esp, 4
		test eax, eax
		jz sscanf_readFloat_internal_loop_end
		
		test dword[ebp-28], 0xffffffff
		jnz sscanf_readFloat_internal_loop_digit_fraction
			mov al, byte[esi]
			sub al, '0'
			movzx eax, al
			
			mov ecx, dword[ebp-16]
			imul ecx, 10
			add ecx, eax
			mov dword[ebp-16], ecx
			
			inc dword[ebp-8]
			jmp sscanf_readFloat_internal_loop_continue
			
		sscanf_readFloat_internal_loop_digit_fraction:
			mov al, byte[esi]
			sub al, '0'
			movzx eax, al
			
			mov ecx, dword[ebp-20]
			imul ecx, 10
			add ecx, eax
			mov dword[ebp-20], ecx
			
			inc dword[ebp-12]
		
		sscanf_readFloat_internal_loop_continue:
		inc dword[ebp-4]
		inc esi
		jmp sscanf_readFloat_internal_loop_start
	sscanf_readFloat_internal_loop_end:
	
	;check if the read was successful
	test dword[ebp-8], 0xffffffff
	jnz sscanf_readFloat_internal_successful_read
	test dword[ebp-12], 0xffffffff
	jnz sscanf_readFloat_internal_successful_read
		mov dword[ebp-4], -1
		jmp sscanf_readFloat_internal_end
	sscanf_readFloat_internal_successful_read:
	
	;construct the float
	cvtsi2ss xmm0, dword[ebp-16]
	
	cvtsi2ss xmm1, dword[ebp-20]
	movss xmm2, dword[P10]
	mov ebx, dword[ebp-12]
	cmp ebx, 0
	jle sscanf_readFloat_internal_convert_fraction_loop_end
	sscanf_readFloat_internal_convert_fraction_loop_start:
		mulss xmm1, xmm2
		dec ebx
		jnz sscanf_readFloat_internal_convert_fraction_loop_start
	sscanf_readFloat_internal_convert_fraction_loop_end:
	
	addss xmm0, xmm1
	mov ecx, dword[ebp+24]
	mov ecx, dword[ecx]
	movss dword[ecx], xmm0
	
	sscanf_readFloat_internal_end:
	mov eax, dword[ebp-4]
	
	mov esp, ebp
	pop ebx
	pop edi
	pop esi
	pop ebp
	ret