[BITS 32]

section .rodata use32
	
	insert_string_format db "%s",0
	
	insert_handlers:	;int insert_handler(char* buffer, void* addrInsertee), returns the number of new characters in the buffer
		;handler, format string length, format string address, insertee length
		dd sprintf_insertString_internal, 2, insert_string_format, 4
		dd 0
	

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