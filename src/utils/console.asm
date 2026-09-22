[BITS 32]

%macro dll_import 2
	import %2 %1
	extern %2
%endmacro

section .rodata use32
	printf_argument_format_string db "%s"
	printf_argument_format_char db "%c"
	printf_argument_format_signed_int db "%d"
	printf_argument_format_float db "%f"

	printf_arguments:	;format string, format string length, argument length
	dd printf_argument_format_string, 2, 4
	dd printf_argument_format_char, 2, 4
	dd printf_argument_format_signed_int, 2, 4
	dd printf_argument_format_float, 2, 4
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
	
	global printf
	global scanf				;int scanf(const char*, ...)
	global console_bookmark		;void console_bookmark()	//detached from every other console utils, prints a small message for debugging
	
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
	mov esi, dword[ebp+20]
	printf_argument_loop_start:
		test byte[esi], 0xff
		jz printf_argument_loop_end
		cmp byte[esi], '%'
		jne printf_argument_loop_continue
			mov edi, printf_arguments
			printf_argument_loop_inner_start:
				test dword[edi], 0xffffffff
				jz printf_error_invalid_format_string
				push dword[edi+4]
				push dword[edi]
				push esi
				call memcmp
				add esp, 12
				test eax, eax
				jnz printf_argument_loop_inner_continue
					mov eax, dword[edi+8]
					add dword[ebp-12], eax
					add esi, dword[edi+4]
					dec esi					;esi is incremented at continue
					jmp printf_argument_loop_inner_end
					
				printf_argument_loop_inner_continue:
				add edi, 12
				jmp printf_argument_loop_inner_start
			printf_argument_loop_inner_end:
		
		printf_argument_loop_continue:
		inc esi
		jmp printf_argument_loop_start
		
	printf_argument_loop_end:
	
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
	test dword[stdout_handle], 0xffffffff
	jnz printf_skip_std_handle_query
		push -11
		call [GetStdHandle]
		mov dword[stdout_handle], eax
	printf_skip_std_handle_query:
	
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