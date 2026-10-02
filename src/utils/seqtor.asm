[BITS 32]

;struct Seqtor{
;	int numElements;
;	int capacity;
;	int sizePerElement;
;	void* elements;
;}	16 bytes

section .text use32

	global seqtor_create			;Seqtor* seqtor_create(int elementSize, int capacity)
	global seqtor_destroy			;void seqtor_destroy(Seqtor*)
	global seqtor_push_back
	
	extern malloc
	extern realloc
	extern free
	extern printf
	extern memcpy
	
seqtor_create:
	push ebp
	mov ebp, esp
	
	sub esp, 4			;seqtor
	sub esp, 4			;elements
	
	mov dword[ebp-4], 0
	mov dword[ebp-8], 0
	
	;check if the params are kosher
	cmp dword[ebp+8], 0
	jg seqtor_create_size_gut
		push dword[ebp+8]
		push seqtor_create_error_invalid_size
		call printf
		jmp seqtor_create_end
		seqtor_create_error_invalid_size db "seqtor_create: %d is not a valid element size",10,0
	seqtor_create_size_gut:
	
	cmp dword[ebp+12], 0
	jge seqtor_create_capacity_gut
		push dword[ebp+12]
		push seqtor_create_error_invalid_capacity
		call printf
		jmp seqtor_create_end
		seqtor_create_error_invalid_capacity db "seqtor_create: %d is not a valid capacity",10,0
	seqtor_create_capacity_gut:
	
	;allocate the seqtor
	push 16
	call malloc
	mov dword[ebp-4], eax
	
	;allocate the memory region if necessary
	test dword[ebp+12], 0xffffffff
	jz seqtor_create_capacity_zero
		mov ecx, dword[ebp+8]
		imul ecx, dword[ebp+12]
		push ecx
		call malloc
		mov dword[ebp-8], eax
		
	seqtor_create_capacity_zero:
	
	;init the values
	mov eax, dword[ebp-4]
	
	mov dword[eax], 0
	mov ecx, dword[ebp+12]
	mov dword[eax+4], ecx
	mov edx, dword[ebp+8]
	mov dword[eax+8], edx
	mov ecx, dword[ebp-8]
	mov dword[eax+12], ecx
	
	seqtor_create_end:
	mov eax, dword[ebp-4]
	
	mov esp, ebp
	pop ebp
	ret
	
	
seqtor_destroy:
	push ebp
	mov ebp, esp
	
	mov eax, dword[ebp+8]
	push dword[eax+12]
	push eax
	call free
	add esp, 4
	call free
	
	mov esp, ebp
	pop ebp
	ret
	
;internal functionos  -----------------------


;void func(Seqtor*, int newSize)
seqtor_changeSize_internal:
	push ebp
	mov ebp, esp
	
	sub esp, 4		;new capacity
	
	mov eax, dword[ebp+8]
	mov ecx, dword[ebp+12]
	
	;check if the new size is kosher
	cmp ecx, 0
	jl seqtor_changeSize_internal_end
	
	;check if the size has changed at all
	cmp dword[eax], ecx
	je seqtor_changeSize_internal_end
	
	;check if the new size (so capacity as well) is zero
	test ecx, ecx
	jnz seqtor_changeSize_internal_new_capacity_not_zero
		push dword[eax+12]
		call free
		mov eax, dword[ebp+8]
		mov dword[eax], 0
		mov dword[eax+4], 0
		mov dword[eax+12], 0
		jmp seqtor_changeSize_internal_end
		
	seqtor_changeSize_internal_new_capacity_not_zero:
	
	;check if the old capacity is zero
	test dword[eax+4], 0xffffffff
	jnz seqtor_changeSize_internal_old_capacity_not_zero
		imul ecx, dword[eax+8]
		push ecx
		call malloc
		mov edx, dword[ebp+8]
		mov dword[edx+12], eax
		
		mov ecx, dword[ebp+12]
		mov dword[eax], ecx
		mov dword[eax+8], ecx
		jmp seqtor_changeSize_internal_end
		
	seqtor_changeSize_internal_old_capacity_not_zero:
	
	;check if the capacity needs to change
	cmp ecx, dword[eax+4]
	je seqtor_changeSize_internal_end
	jl seqtor_changeSize_internal_new_size_smaller
		;the new size became greater
		mov edx, dword[eax+4]
		seqtor_changeSize_internal_new_size_greater_loop_start:
			shl edx, 1
			cmp edx, ecx
			jl seqtor_changeSize_internal_new_size_greater_loop_start
		mov dword[ebp-4], edx
		imul edx, dword[eax+8]
		push edx
		push dword[eax+12]
		call realloc
		
		mov edx, dword[ebp+8]
		mov ecx, dword[ebp+12]
		mov dword[edx], ecx
		mov ecx, dword[ebp-4]
		mov dword[edx+4], ecx
		mov dword[edx+12], eax
		
		jmp seqtor_changeSize_internal_end
		
	seqtor_changeSize_internal_new_size_smaller:
		mov edx, dword[eax+4]
		mov ecx, edx
		seqtor_changeSize_internal_new_size_smaller_loop_start:
			shr ecx, 1
			cmp ecx, dword[ebp+12]
			jl seqtor_changeSize_internal_new_size_smaller_loop_end
			mov edx, ecx
			jmp seqtor_changeSize_internal_new_size_smaller_loop_start
		seqtor_changeSize_internal_new_size_smaller_loop_end:
		
		mov dword[ebp-4], edx
		
		imul edx, dword[eax+8]
		push edx
		push dword[eax+12]
		call realloc
		
		mov edx, dword[ebp+8]
		mov ecx, dword[ebp+12]
		mov dword[edx], ecx
		mov ecx, dword[ebp-4]
		mov dword[edx+4], ecx
		mov dword[edx+12], eax
		
		jmp seqtor_changeSize_internal_end
	
	seqtor_changeSize_internal_end:
	mov esp, ebp
	pop ebp
	ret
	