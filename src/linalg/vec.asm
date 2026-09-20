[BITS 32]

;struct Vec{
;	int elementCount;
;	float* elements;
;	//helper values
;	int elementQuadCount;		;elementCount/4
;	int elementQuadRemainder;	;elementCount%4
;} 4+4*elementCount bytes

section .rodata use32

	ZERO dd 0.0

	error_create_invalid_length db "vec_create: %d is not a valid vector length",10,0
	error_resize_invalid_length db "vec_resize: %d is not a valid vector length",10,0

section .text use32

	global vec_create		;vec* vec_create(int length)
	global vec_destroy		;void vec_destroy(vec*)
	global vec_resize		;void vec_resize(vec*, int length)
	
	global vec_get			;float vec_get(vec*, int)			;returns the value in xmm0
	global vec_set			;void vec_set(vec*, int, float)
	
	extern malloc
	extern free
	extern realloc
	
	extern memset
	
	extern printf
	
vec_create:
	push ebp
	mov ebp, esp
	
	sub esp, 4			;vec
	sub esp, 4			;inner array
	
	mov dword[ebp-4], 0
	
	;check if the length is valid
	cmp dword[ebp+8], 0
	jg vec_create_length_valid
		push dword[ebp+8]
		push error_create_invalid_length
		call printf
		jmp vec_create_end
		
	vec_create_length_valid:
	
	;alloc the vector
	push 8
	call malloc
	mov dword[ebp-4], eax
	
	;alloc the inner array
	mov eax, dword[ebp+8]
	shl eax, 2
	push eax
	call malloc
	mov dword[ebp-8], eax
	
	push 0
	push eax
	call memset
	
	;init the values
	mov eax, dword[ebp-4]
	
	mov ecx, dword[ebp+8]
	mov dword[eax], ecx
	mov edx, dword[ebp-8]
	mov dword[eax+4], edx
	
	push eax
	call vec_calculateHelperValues_internal
	
	
	vec_create_end:
	mov eax, dword[ebp-4]
	
	mov esp, ebp
	pop ebp
	ret
	
	
vec_destroy:
	push ebp
	mov ebp, esp
	
	test dword[ebp+8], 0xffffffff
	jz vec_destroy_end
	
	mov eax, dword[ebp+8]
	push eax
	push dword[eax+4]
	call free
	add esp, 4
	call free
	
	vec_destroy_end:
	mov esp, ebp
	pop ebp
	ret
	
	
vec_resize:
	push ebp
	mov ebp, esp
	
	;check if the length is valid
	cmp dword[ebp+12], 0
	jg vec_resize_length_valid
		push dword[ebp+12]
		push error_resize_invalid_length
		call printf
		jmp vec_resize_end
		
	vec_resize_length_valid:
	
	;realloc the inner array
	mov eax, dword[ebp+12]
	shl eax, 2
	mov ecx, dword[ebp+8]
	push eax
	push dword[ecx+4]
	call realloc
	mov ecx, dword[ebp+8]
	mov dword[ecx+4], eax
	
	;zero out the new parts if necessary
	mov edx, dword[ebp+12]
	cmp edx, dword[ecx]
	jle vec_resize_skip_memset
		sub edx, dword[ecx]
		shl edx, 2
		
		mov eax, dword[ecx]
		shl eax, 2
		add eax, dword[ecx+4]
		
		push edx
		push 0
		push eax
		call memset
		
	vec_resize_skip_memset:
	
	;update the values
	mov eax, dword[ebp+8]
	
	mov ecx, dword[ebp+12]
	mov dword[eax], ecx
	
	push eax
	call vec_calculateHelperValues_internal
	
	
	vec_resize_end:
	mov esp, ebp
	pop ebp
	ret
	
	
vec_get:
	push ebp
	mov ebp, esp
	
	test dword[ebp+8], 0xffffffff
	jnz vec_get_not_null
		push error_get_vector_null
		call printf
		xorps xmm0, xmm0
		jmp vec_get_end
	vec_get_not_null:
	
	push dword[ebp+12]
	push dword[ebp+8]
	call vec_isValidIndex_internal
	xorps xmm0, xmm0
	test eax, eax
	jz vec_get_end
	
	mov eax, dword[ebp+8]
	mov ecx, dword[ebp+12]
	mov eax, dword[eax+4]
	movss xmm0, dword[eax+4*ecx]
	
	vec_get_end:
	mov esp, ebp
	pop ebp
	ret
	error_get_vector_null db "vec_get: vector is NULL",10,0
	error_get_invalid_index db "vec_get: %d is not a valid index for a vector of size %d",10,0
	
	
vec_set:
	push ebp
	mov ebp, esp
	
	test dword[ebp+8], 0xffffffff
	jnz vec_set_not_null
		push error_set_vector_null
		call printf
		jmp vec_set_end
	
	vec_set_not_null:
	
	push dword[ebp+12]
	push dword[ebp+8]
	call vec_isValidIndex_internal
	test eax, eax
	jnz vec_set_valid_index
		mov eax, dword[ebp+8]
		push dword[eax]
		push dword[ebp+12]
		push error_set_invalid_index
		call printf
		jmp vec_set_end
		
	vec_set_valid_index:
	
	mov eax, dword[ebp+8]
	mov eax, dword[eax+4]
	mov ecx, dword[ebp+12]
	mov edx, dword[ebp+16]
	
	mov dword[eax+4*ecx], edx
	
	vec_set_end:
	mov esp, ebp
	pop ebp
	ret
	error_set_vector_null db "vec_set: vector is NULL",10,0
	error_set_invalid_index db "vec_set: %d is not a valid index for a vector of size %d",10,0
	
	
;internal funcitons

;void vec_calculateHelperValues_internal(Vec*)
vec_calculateHelperValues_internal:
	push ebp
	mov ebp, esp
	
	mov ecx, dword[ebp+8]
	mov eax, dword[ecx]
	xor edx, edx
	mov ecx, 4
	idiv ecx
	
	mov ecx, dword[ebp+8]
	mov dword[ecx+8], eax
	mov dword[ecx+12], edx
	
	mov esp, ebp
	pop ebp
	ret
	
	
;int vec_isValidIndex_internal(Vec*, int)
vec_isValidIndex_internal:
	xor eax, eax
	
	mov ecx, dword[esp+4]
	mov edx, dword[esp+8]
	cmp edx, 0
	jl vec_isValidIndex_internal_end
	cmp edx, dword[ecx]
	jge vec_isValidIndex_internal_end
	
	mov eax, 67
	
	vec_isValidIndex_internal_end:
	ret