[BITS 32]

%macro dll_import 2
	import %2 %1
	extern %2
%endmacro

;typedef HANDLE FILE*

section .rodata use32
	;seek enums same as in winapi
	FSEEK_BEGIN dd 0
	FSEEK_CURRENT dd 1
	FSEEK_END dd 2
	
	global FSEEK_BEGIN
	global FSEEK_CURRENT
	global FSEEK_END
	
	INVALID_SET_FILE_POINTER equ -1

section .text use32

	global fseek		;int fseek(FILE*, int offset, enum origin)
	global fgets		;void* fgets(char*, int, FILE*)		//includes line end, but removes/swaps all CR characters to LF
	
	dll_import kernel32.dll, SetFilePointer
	dll_import kernel32.dll, ReadFile
	
	
fseek:
	push ebp
	mov ebp, esp
	
	push dword[ebp+16]
	push 0
	push dword[ebp+12]
	push dword[ebp+8]
	call [SetFilePointer]
	
	mov ecx, eax
	mov eax, 0
	cmp ecx, INVALID_SET_FILE_POINTER
	jne fseek_end
		mov eax, 67
	
	fseek_end:
	mov esp, ebp
	pop ebp
	ret
	
	
fgets:
	push ebp
	push esi
	push edi
	push ebx
	mov ebp, esp
	
	sub esp, 4			;characters read	4
	sub esp, 4			;return value		8
	
	mov dword[ebp-4], 0
	mov eax, dword[ebp+20]
	mov dword[ebp-8], eax
	
	;read the line
	mov eax, dword[ebp+24]
	dec eax						;keep place for the \0
	lea ecx, [ebp-4]
	push 0
	push ecx
	push eax
	push dword[ebp+20]
	push dword[ebp+28]
	call [ReadFile]
	
	test eax, eax
	jz fgets_read_successful
	test dword[ebp-4], 0xffffffff
	jz fgets_read_unsuccessful
	fgets_read_unsuccessful:
		mov dword[ebp-8], 0
		jmp fgets_end
	fgets_read_successful:
	
	;check if there are any line end characters
	mov esi, dword[ebp+20]
	xor edi, edi				;index, should point to after the end of the first line end if one is found
	xor ebx, ebx				;line end length, stays zero if no line end is found
	fgets_line_end_loop_start:
		;is line end?
		cmp byte[esi+edi], 10		;lf
		je fgets_line_end_loop_lf
		cmp word[esi+edi], 0x0a0d	;crlf
		je fgets_line_end_loop_crlf
		cmp byte[esi+edi], 13		;cr
		je fgets_line_end_loop_cr
		jmp fgets_line_end_loop_continue
		
		fgets_line_end_loop_lf:
			inc edi
			mov ebx, 1
			jmp fgets_line_end_loop_end
			
		fgets_line_end_loop_cr:
			inc edi
			mov byte[esi+edi], 10		;swap cr
			mov ebx, 1
			jmp fgets_line_end_loop_end
			
		fgets_line_end_loop_crlf:
			add edi, 2
			mov byte[esi+edi], 10		;swap cr
			mov ebx, 2
			jmp fgets_line_end_loop_end
		
		fgets_line_end_loop_continue:
		inc edi
		cmp edi, dword[ebp-4]
		jl fgets_line_end_loop_start
	fgets_line_end_loop_end:
	
	;move back the file pointer if necessary
	cmp edi, dword[ebp-4]
	je fgets_skip_fseek
		mov eax, dword[ebp-4]
		sub eax, edi
		push dword[FSEEK_CURRENT]
		push eax
		push dword[ebp+28]
		call fseek
		add esp, 12
	fgets_skip_fseek:
	
	;place the ending zero
	test ebx, ebx
	jz fgets_zero_no_line_end
		mov edx, edi
		neg edx
		mov byte[esi+edx], 0
		jmp fgets_zero_placed
	fgets_zero_no_line_end:
		mov byte[esi], 0
	fgets_zero_placed:
	
	fgets_end:
	mov eax, dword[ebp-8]
	
	mov esp, ebp
	pop ebx
	pop edi
	pop esi
	pop ebp
	ret
	fgets_isLineEnd:		;int func(int c)
		xor eax, eax
		mov ecx, dword[esp+4]
		cmp cl, 10
		je fgets_isLineEnd_it_is
		cmp cl, 13
		je fgets_isLineEnd_it_is
		jmp fgets_isLineEnd_it_is_not
		fgets_isLineEnd_it_is:
			mov eax, 67
		fgets_isLineEnd_it_is_not:
		ret