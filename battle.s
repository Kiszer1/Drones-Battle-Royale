BOARD EQU 100
		
section .bss
	global coRoutines
	global N
	global R
	global K
	global T
	global d
	global infoStack
	global aliveDrones
	global stacks
	global seed
	global scale
	global scaled_seed
	global schedulerAddr
	global schedulerStack
	global targetAddr
	global targetStack
	global printerAddr
	global printerStack

	SPT:		resd	1
	STKSZ:		equ	16*1024
	stacks: 	resb    4			; the drones coRoutines stacks
	infoStack: 	resb	4			; array with 5 bytes for each drone to hold drone info
	coRoutines	resb	4			; array of 8 bytes for each co - routine with position and func 
	aliveDrones	resb 	4			; array of 8 bytes for each drone
	count:  	resb	1
	N: 		resb	4			; number of drones
	R: 		resb	4			; number of full scheduler cycles between each elimination
	K:		resb	4			; how many drones steps between game board printings
	T:		resb	4			; how many drone steps between target moves randomly
	d:		resb	4			; maximum distance that allows to destroy a target (at most 20)
	seed:		resb	4			; seed for initialization of LFSR shift register
	scaled_seed:	resb	4
	scale:		resb	4
	angle:		resb	1
	
	targetAddr:	resb	4
	targetStack:	resb	STKSZ
	schedulerAddr:  resb	4
	schedulerStack: resb	STKSZ
	printerAddr:	resb	4
	printerStack:	resb 	STKSZ
	

section .data
	MAXINT:		dd	0xFFFF

section .text
	align 16
	global main
	global getRandomNumb
	extern printf 
	extern malloc 
	extern calloc 
	extern free 
	extern sscanf
	extern createTarget
	extern target
	extern drone
	extern scheduler
	extern printer
	extern start


main:	
	push ebp
	mov ebp, esp
	pushad
	mov ecx, 10			; for inc digits in base 10
	mov eax, 0			; eax will be used as "sum"
	mov esi, [ebp + 12]		; esi points to first char args

	call getArgs			; get and set args
	call createTarget		; create target
	
	mov eax, [N]
	mov ebx, stacks
	mov ecx, STKSZ
	call createStack		; creating a stack for each drone co-routine


	
	mov eax, [N]
	mov ebx, infoStack		; allocate infoStack
	mov ecx, 20
	call createStack		; creating a stack for drone information
	


	call alive_Drones		; set array of 8 bytes to mark if each drone is dead or alive
	call initDrones			; set drones info
	call co_Routines		; set co routines addresses and funcs
	call initCors
	call initDroneCors
	call initStacks
	call start

	popad
	mov esp, ebp
	pop ebp
	ret

getArgs:
	mov ebx, [esi + 4]
	call setArgs
	mov [N], eax
	mov eax, 0
	mov ebx, [esi + 8]
	call setArgs
	mov [R], eax
	mov eax, 0
	mov ebx, [esi + 12]
	call setArgs
	mov [K], eax
	mov eax, 0
	mov ebx, [esi + 16]
	call setArgs
	mov [T], eax
	mov eax, 0
	mov ebx, [esi + 20]
	call setArgs
	mov [d], eax
	mov eax, 0
	mov ebx, [esi + 24]	
	call setArgs
	mov [seed], eax
	ret

setArgs: 
	add al, [ebx]
	sub al, '0'
	inc ebx
	cmp byte [ebx], 0
	jne nextChar
	ret
nextChar:
	mul ecx
	jmp setArgs






getRandomNumb:
	call randomNumb
	finit
	fild dword [seed]
	fidiv dword [MAXINT]
	fimul dword [scale]
	fstp dword [scaled_seed]
	ret
	
	


randomNumb:
	push ebp
	mov ebp, esp
	pushad
	mov ecx, 16
	mov ax, [seed]
randomLoop:
	mov bh, 1
	mov bl, 4
	mov dh, 8
	mov dl, 32
	and bh, al
	and bl, al
	and dh, al
	and dl, al
	shr bl, 2
	shr dh, 3
	shr dl, 5
	xor bh, bl
	xor bh, dh
	xor bh, dl
	shr ax, 1
	mov bl, 0
	shl bh, 7
	or ax, bx
	loop randomLoop
	mov [seed], ax
	popad
	leave
	ret
	



createStack:
	mul ecx
	push eax
	call malloc
	add esp, 4
	mov [ebx], eax
	ret	




alive_Drones:
	push dword [N]			; allocating 1 byte for each drone
	call malloc
	add esp, 4
	mov [aliveDrones], eax
	mov ecx, [N]	
alive_Loop:
	mov byte [eax], 1
	inc eax
	loop alive_Loop
	ret




initDrones:
	mov eax, [infoStack]
	mov edx, [N]
initLoop:
	mov dword [scale], BOARD
	dec edx
	mov ecx, 2
	call droneInfo
	cmp edx, 0
	jne initLoop
	ret


droneInfo:
	call getRandomNumb		; generate x , y and speed
	mov ebx, [scaled_seed]
	mov [eax], ebx
	add eax, 4
	loop droneInfo
	mov dword [scale], 360
	call getRandomNumb
	mov ebx, [scaled_seed]
	mov [eax], ebx
	add eax, 4
	mov dword [scale], 255		; max speed is 255
	call getRandomNumb
	mov ebx, [scaled_seed]
	mov [eax], ebx
	add eax, 4
	mov dword [eax], 0		; 0 targets destroyed
	add eax, 4
	ret
	

co_Routines:
	mov eax, [N]
	add eax, 3
	mov ecx, 8
	mov ebx, coRoutines
	call createStack
	ret


initCors:
	mov ebx, [coRoutines]
	mov ecx, [N]
	add ecx, 2
	mov eax, target
	mov edx, targetStack
	mov [targetAddr], ecx		; save position of co routine
	call initCor

	dec ecx
	mov eax, scheduler
	mov edx, schedulerStack
	mov [schedulerAddr], ecx
	call initCor
	
	dec ecx
	mov eax, printer
	mov edx, printerStack
	mov [printerAddr], ecx
	call initCor
	ret



initCor: 
	add edx, STKSZ			; point to the top of the stack
	mov [ebx + ecx*8], eax
	mov [ebx + ecx*8 + 4], edx
	ret
	


initDroneCors:
	mov eax, [N]
	mov ebx, STKSZ
	mul ebx				; drones stack size now in eax
	mov ebx, [stacks]
	add eax, ebx			; eax points to the top of the stack
	mov ecx, [N]
	dec ecx
	mov edx, [coRoutines]
corsLoop:
	mov dword [edx + ecx*8], drone
	mov [edx + ecx*8 + 4], eax
	sub eax, STKSZ
	loop corsLoop
	mov dword [edx], drone		; set first drone
	mov dword [edx + 4], eax	
	ret


initStacks:
	mov ecx, [N]
	add ecx, 2
stacksLoop:
	mov eax, [coRoutines]		
	mov [SPT], esp			; SPT holds current esp
	mov ebx, [eax + ecx*8]		; ebx holds pointer to the co routine code 
	mov esp, [eax + ecx*8 + 4]	; esp holds pointer to current stack
	; pushing into co routine stack 
	push ebx			; push code addr
	pushfd				; push flags
	pushad 				; push registers
	mov [eax + ecx*8 + 4], esp	; stack should start after backup
	mov esp, [SPT]			; restore esp
	dec ecx
	cmp ecx, 0
	jge stacksLoop
	ret
	

