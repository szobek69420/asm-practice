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
	test_text6 db "%d",0
	test_text7 db "%s",10,0
	test_text8 db "%c",10,0
	test_text9 db "%f",10,0
	test_text10 db "%s %f",10,0
	
	sus dd -6744.06742
	
section .bss use32
	string_buffer resb 200

section .text use32
	
	dll_import kernel32.dll, ExitProcess
	
	extern printf
	extern scanf
	extern stdin
	extern fgets
	extern console_bookmark
	
	..start:
		push ebp
		mov ebp, esp
	
		sub esp, 4		;arg
		sub esp, 4		;arg2
	
		finit
	
		mov dword[ebp-4], 0
		mov dword[ebp-8], 0
		
		lea eax, [ebp-4]
		push eax
		push string_buffer
		push test_text10
		call scanf
		
		push dword[ebp-4]
		push string_buffer
		push test_text10
		call printf

		
		mov esp, ebp
		pop ebp
		
		push 0
		call [ExitProcess]