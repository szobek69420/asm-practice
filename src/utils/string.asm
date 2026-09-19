[BITS 32]

section .rodata use32
	PRINTF_FLOAT_PRECISION equ 3
	
	insert_string_format db "%s",0
	insert_char_format db "%c",0
	insert_signed_int_format db "%d",0
	insert_float_format db "%f",0
	
	insert_handlers:	;int insert_handler(char* buffer, void* addrInsertee), returns the number of new characters in the buffer
		;handler, format string length, format string address, insertee length
		dd sprintf_insertString_internal, 2, insert_string_format, 4
		dd sprintf_insertChar_internal, 2, insert_char_format, 4		;note that a char is also 4 bytes in the argument list
		dd sprintf_insertSignedInt_internal, 2, insert_signed_int_format, 4
		dd sprintf_insertFloat_internal, 2, insert_float_format, 4
		dd 0
	
	P10 dd 0.1

section .text use32

	extern memcmp
	extern console_bookmark

	global strlen		;int strlen(const char* string)
	global sprintf		;int sprintf(char* buffer, const char* format, ...)

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