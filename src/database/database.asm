[BITS 32]

;struct Database{
;	int rowSizeInBytes;		0
;	void* idAndRowData;		4
;	int nextId;				8
;}		12 bytes

section .rodata use32

section .text use32
	
	global database_create		;Database* database_create(int rowSizeInBytes)
	
database_create