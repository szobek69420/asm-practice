[BITS 32]

%macro dll_import 2
	import %2 %1
	extern %2
%endmacro

section .rodata use32
	argument_format_string db "%s"
	argument_format_char db "%c"
	argument_format_signed_int db "%d"
	argument_format_float db "%f"

	arguments:	;format string, format string length, argument length
	dd argument_format_string, 2, 4
	dd argument_format_char, 2, 4
	dd argument_format_signed_int, 2, 4
	dd argument_format_float, 2, 4
	dd 0
	
	error_invalid_format_string db "printf: Invalid format string",10,0
	
	bookmark_text db "bookmark",10,0

section .bss use32
	printf_buffer resb 2048

section .data use32
	stdin_handle dd 0
	stdout_handle dd 0
	
section .text use32
	
	dll_import kernel32.dll, GetStdHandle
	dll_import kernel32.dll, WriteFile
	
	extern sprintf
	extern memcmp
	extern memcpy
	
	global stdin				;HANDLE stdin()
	global stdout				;HANDLE stdout()
	
	global printf
	global scanf				;int scanf(const char*, ...)
	global console_bookmark		;void console_bookmark()	//detached from every other console utils, prints a small message for debugging
	
stdin:
	mov eax, dword[stdin_handle]
	test eax, eax
	jnz stdin_end
		push -10
		call [GetStdHandle]
		mov dword[stdin_handle], eax
	stdin_end:
	ret
	
	
stdout:
	mov eax, dword[stdout_handle]
	test eax, eax
	jnz stdout_end
		push -11
		call [GetStdHandle]
		mov dword[stdout_handle], eax
	stdout_end:
	ret
	
	
printf:		;NOTE: this function is not at all thread-safe
	push ebp
	push esi
	push edi
	push ebx
	mov ebp, esp
	
	sub esp, 4		;length of string
	sub esp, 4		;number of characters written
	sub esp, 4		;argument lengths
	sub esp, 4		;return value
	
	mov dword[ebp-12], 0
	
	;determine the size of the arguments
	push dword[ebp+20]
	call console_formatArgumentSize_internal
	add esp, 4
	mov dword[ebp-12], eax
	cmp dword[ebp-12], -1
	je printf_error_invalid_format_string
	
	;call sprintf
	sub esp, dword[ebp-12]
	
	mov eax, esp
	lea ecx, [ebp+24]
	push dword[ebp-12]
	push ecx
	push eax
	call memcpy
	add esp, 12
	
	push dword[ebp+20]
	push printf_buffer
	call sprintf
	mov dword[ebp-4], eax
	add esp, 8
	add esp, dword[ebp-12]
	
	;printf the string to the console
	call stdout
	
	push 0
	lea eax, [ebp-8]
	push eax
	push dword[ebp-4]
	push printf_buffer
	push dword[stdout_handle]
	call [WriteFile]
	
	
	;determine the return value
	mov ecx, dword[ebp-8]
	mov dword[ebp-16], ecx

	cmp ecx, dword[ebp-4]
	je printf_keep_return_value
		mov dword[ebp-16], -67
	printf_keep_return_value:
	
	
	printf_end:
	mov eax, dword[ebp-16]
	
	mov esp, ebp
	pop ebx
	pop edi
	pop esi
	pop ebp
	ret
	printf_error_invalid_format_string:
		mov dword[ebp-16], -67
		jmp printf_end
		
scanf:
	push ebp
	push esi
	push edi
	push ebx
	mov ebp, esp
	
	sub esp, 4		;sum size of args		4
	
	
	
	mov esp, ebp
	pop ebx
	pop edi
	pop esi
	pop ebp
	ret
	
	
	
console_bookmark:
	push eax
	push ecx
	push edx
	
	push -11
	call [GetStdHandle]
	
	push 0
	push 0
	push 9
	push bookmark_text
	push eax
	call [WriteFile]
	
	pop edx
	pop ecx
	pop eax
	ret
	
	
;internal functions

;int console_formatArgumentSize_internal(const char* format)		//calculates the size of arguments that a format indicates. returns -1 on invalid format
console_formatArgumentSize_internal:
	push ebp
	push esi
	push edi
	push ebx
	mov ebp, esp
	
	sub esp, 4			;argument count		4
	sub esp, 4			;argument size		8
	
	mov dword[ebp-4], 0
	mov dword[ebp-8], 0
	
	mov esi, dword[ebp+20]
	xor edi, edi
	console_formatArgumentSize_internal_loop_start:
		test byte[esi+edi], 0xff
		jz console_formatArgumentSize_internal_loop_end
		cmp byte[esi+edi], '%'
		jne console_formatArgumentSize_internal_loop_continue
			;check for the type of argument
			mov ebx, arguments
			console_formatArgumentSize_internal_inner_loop_start:
				test dword[ebx], 0xffffffff
				jz console_formatArgumentSize_internal_inner_loop_end
					lea eax, [esi+edi]
					push dword[ebx+4]
					push dword[ebx]
					push eax
					call memcmp
					add esp, 12
					test eax, eax
					jnz console_formatArgumentSize_internal_inner_loop_continue
					
					inc dword[ebp-4]
					mov ecx, dword[ebx+8]
					add dword[ebp-8], ecx
					
					add edi, dword[ebx+4]
					dec edi
					jmp console_formatArgumentSize_internal_loop_continue	;note that this jumps to the outer loop
				
				console_formatArgumentSize_internal_inner_loop_continue:
				add ebx, 12
				jmp console_formatArgumentSize_internal_inner_loop_start
			console_formatArgumentSize_internal_inner_loop_end:
			;if we're here, problemo
			mov dword[ebp-4], -1
			mov dword[ebp-8], -1
			jmp console_formatArgumentSize_internal_loop_end
		
		console_formatArgumentSize_internal_loop_continue:
		inc edi
		jmp console_formatArgumentSize_internal_loop_start
	console_formatArgumentSize_internal_loop_end:
	
	console_formatArgumentSize_internal_end:
	mov eax, dword[ebp-8]
	
	mov esp, ebp
	pop ebx
	pop edi
	pop esi
	pop ebp
	ret