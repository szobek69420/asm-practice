[BITS 32]

%macro dll_import 2
	import %2 %1
	extern %2
%endmacro

section .rodata use32
	test_text db "sussy nigga",0
	test_text2 db "%s%s",10,0
	test_text3 db "%d bomboclat pussywagon chicken nuggets",0
	test_text4 db "hello neighbour %f",0
	test_text5 db "my name is %c",0
	
	sus dd -6744.06742
	
section .bss use32
	string_buffer resb 200

section .text use32
	
	dll_import kernel32.dll, ExitProcess
	
	extern printf
	extern stdin
	extern fgets
	extern console_bookmark
	
	..start:
		push ebp
		mov ebp, esp
	
		finit
		
		sub esp, 4		;string length
	
		
		call stdin
		push eax
		push 10
		push string_buffer
		call fgets
		
		push test_text
		push test_text2
		call printf
		add esp, 8
		
		call fgets
		push test_text
		push test_text2
		call printf
		add esp, 8

		
		mov esp, ebp
		pop ebp
		
		push 0
		call [ExitProcess]