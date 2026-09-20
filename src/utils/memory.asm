[BITS 32]

%macro dll_import 2
	import %2 %1
	extern %2
%endmacro

section .rodata use32

	error_free db "free: an error occured at deallocation",10,0

section .data use32

	heap_handle dd 0

section .text use32

	global malloc			;void* malloc(int numBytes)
	global free				;void free(void* data)
	global realloc			;void* realloc(void* data, int numBytes)

	global memcpy			;void* memcpy(void* dest, const void* src, int numBytes)
	global memcmp			;int memcmp(const void* mem1, const void* mem2, int numBytes)
	global memset			;void* memset(void* data, int c, int numBytes)
	
	dll_import kernel32.dll, GetProcessHeap
	dll_import kernel32.dll, HeapAlloc
	dll_import kernel32.dll, HeapReAlloc
	dll_import kernel32.dll, HeapFree
	
	extern printf
	
	
	malloc:
		push ebp
		mov ebp, esp
		
		;check if the byte count is kosher
		xor eax, eax
		cmp dword[ebp+8], 0
		jle malloc_end
		
		;get the heap handle if necessary
		call getHeapHandle_internal
		
		;alloc memory
		push dword[ebp+8]
		push 0
		push dword[heap_handle]
		call [HeapAlloc]
		
		malloc_end:
		mov esp, ebp
		pop ebp
		ret
		
		
	free:
		push ebp
		mov ebp, esp
		
		;test if a null pointer is the freeee
		test dword[ebp+8], 0xffffffff
		jz free_end
		
		;get the heap handle if necessary
		call getHeapHandle_internal
		
		;free
		push dword[ebp+8]
		push 0
		push dword[heap_handle]
		call [HeapFree]
		
		test eax, eax
		jnz free_end
			;problem
			push error_free
			call printf
		
		free_end:
		mov esp, ebp
		pop ebp
		ret
		
	realloc:
		push ebp
		mov ebp, esp
		
		xor eax, eax
		test dword[ebp+8], 0xffffffff
		jz realloc_end
		
		;get the heap
		call getHeapHandle_internal
		
		;realloc
		push dword[ebp+12]
		push dword[ebp+8]
		push 0
		push dword[heap_handle]
		call [HeapReAlloc]
		
		realloc_end:
		mov esp, ebp
		pop ebp
		ret
		
	
	memcpy:
		push ebp
		push esi
		push edi
		mov ebp, esp
		
		mov eax, dword[ebp+24]
		mov esi, dword[ebp+20]
		mov edi, dword[ebp+16]
		cld
		cmp edi, esi
		jbe memcpy_ascend
			add esi, eax
			add edi, eax
			std
		memcpy_ascend:
		
		test eax, eax
		jz memcpy_loop_end
		memcpy_loop_start:
			movsb
			dec eax
			jnz memcpy_loop_start
		memcpy_loop_end:
		
		cld
		
		mov esp, ebp
		pop edi
		pop esi
		pop ebp
		ret
		
	
	memcmp:
		push ebx
		
		mov ebx, dword[esp+16]
		mov ecx, dword[esp+8]
		mov edx, dword[esp+12]
		
		xor eax, eax
		test ebx, ebx
		jz memcmp_loop_end
		
		memcmp_loop_start:
			mov al, byte[ecx]
			sub al, byte[edx]
			movsx eax, al
			test eax, eax
			jnz memcmp_loop_end
		
			memcmp_loop_continue:
			inc ecx
			inc edx
			dec ebx
			test ebx, ebx
			jnz memcmp_loop_start
			xor eax, eax
		memcmp_loop_end:
		
		pop ebx
		ret
		
		
	memset:
		push ebp
		push esi
		push edi
		push ebx
		mov ebp, esp
		
		sub esp, 4			;quad count
		sub esp, 4			;quad remainder
		
		;can we skip?
		cmp dword[ebp+28], 0
		jle memset_end
		
		;propagate the char value to 4 bytes
		mov ebx, dword[ebp+24]
		rol ebx, 8
		mov bl, bh
		rol ebx, 8
		mov bl, bh
		rol ebx, 8
		mov bl, bh
		
		;get the quad values
		mov eax, dword[ebp+28]
		xor edx, edx
		mov ecx, 4
		idiv ecx
		mov dword[ebp-4], eax
		mov dword[ebp-8], edx
		
		;set the quads
		mov esi, dword[ebp+20]
		mov edi, dword[ebp-4]
		test edi, edi
		jz memset_quad_loop_end
		memset_quad_loop_start:
			mov dword[esi], ebx
			add esi, 4
			dec edi
			jnz memset_quad_loop_start
		memset_quad_loop_end:
		
		;set the remainder
		mov edi, dword[ebp-8]
		test edi, edi
		jz memset_remainder_loop_end
		memset_remainder_loop_start:
			mov byte[esi], bl
			inc esi
			dec edi
			jnz memset_remainder_loop_end
		memset_remainder_loop_end:
		
		memset_end:
		mov eax, dword[ebp+20]
		
		mov esp, ebp
		pop ebx
		pop edi
		pop esi
		pop ebp
		ret
		
;internal functinos

getHeapHandle_internal:
	test dword[heap_handle], 0xffffffff
	jnz getHeapHandle_internal_end
		call [GetProcessHeap]
		mov dword[heap_handle], eax
	getHeapHandle_internal_end:
	ret