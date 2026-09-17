[BITS 32]

section .text use32

	global memcpy			;void* memcpy(void* dest, const void* src, int numBytes)
	global memcmp			;int memcmp(const void* mem1, const void* mem2, int numBytes)
	
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