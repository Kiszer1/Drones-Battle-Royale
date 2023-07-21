BOARD    EQU 100
MOVEMENT EQU 20

section .data
	global destroyed
	global x
	global y
	destroyed: 	dd 0
	x:		dd 0
	y:		dd 0
	zero:		dd 0
	ten:		dd 10
	board:		dd 100
	
	

section .text
	align 16
	global target
	global createTarget
	extern printf 
	extern malloc 
	extern calloc 
	extern free 
	extern sscanf
	extern resume
	extern getRandomNumb
	extern schedulerAddr
	extern scale
	extern scaled_seed


target:
	cmp dword [destroyed], 1	
	je droneCall			; target was destroyed by a drone
	finit
	mov dword [scale], MOVEMENT
	call getRandomNumb
	fld dword [x]
	call moveTarget
	fstp dword [x]
	call getRandomNumb
	fld dword [y]
	call moveTarget
	fstp dword [y]
	jmp targetEnd
droneCall:
	call createTarget
targetEnd:
	mov ebx, [schedulerAddr]
	call resume
	jmp target



moveTarget:
	fadd dword [scaled_seed]
	fisub dword [ten]
	fild dword [board]
	fcomip
	ja wrapMinus		; 
	fisub dword [board]		; wrap around top / right edges
wrapMinus:
	fild dword [zero]
	fcomip
	jb moveEnd
	fiadd dword [board]		; wrap around bottom / left edges
moveEnd:
	ret
	


createTarget:
	push ebp
	mov ebp, esp
	pushad
	mov dword [destroyed], 0
	mov dword [scale], BOARD
	call getRandomNumb
	mov eax, [scaled_seed]
	mov [x], eax
	call getRandomNumb
	mov eax, [scaled_seed]
	mov [y], eax
	popad
	mov esp, ebp
	pop ebp
	ret