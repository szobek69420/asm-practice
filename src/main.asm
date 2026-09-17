[BITS 32]

%macro dll_import 2
	import %2 %1
	extern %2
%endmacro

section .rodata use32
	test_text db "sussy nigga",0
	test_text2 db "amogus %s nigga",0
	
section .bss use32
	string_buffer resb 200

section .text use32
	
	dll_import kernel32.dll, ExitProcess
	
	extern printf
	extern console_bookmark
	
	..start:
		push ebp
		mov ebp, esp
	
		finit
		
		sub esp, 4		;string length
	
		
		push test_text
		push test_text2
		call printf
		add esp, 8

		
		mov esp, ebp
		pop ebp
		
		push 0
		call [ExitProcess]