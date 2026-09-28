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
	
	extern vec_create
	extern vec_destroy
	extern vec_print
	
	..start:
		push ebp
		mov ebp, esp
	
		sub esp, 4		;vec
	
		finit
	
		mov dword[ebp-4], 0
		
		push 4
		call vec_create
		mov dword[ebp-4], eax
		
		push eax
		call vec_print
		call vec_destroy
		
		call console_bookmark
		
		mov esp, ebp
		pop ebp
		
		push 0
		call [ExitProcess]