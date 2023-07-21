section .rodata
	format_winner: db "Winner is drone with ID: %d", 10, 0

section .bss
	CURR:		resd	1
	SPT:		resd	1
	SPMAIN: 	resd	1

section .data
	global roundCounter
	aliveNumb:	dd 0
	roundCounter:	dd 0
	printCounter:	dd 0
	moveCounter:	dd 0
	elimCounter: 	dd 0
	minTargets:	dd 0
	eliminate:	dd 0
	
	
	
section .text
	align 16
	global start
	global scheduler
	global resume
	extern N
	extern K
	extern T
	extern R
	extern coRoutines
	extern stacks
	extern targetAddr
	extern infoStack
	extern printerAddr
	extern schedulerAddr
	extern aliveDrones
	extern printf 
	extern malloc 
	extern free 
	extern exit
	

start:
	mov eax, [N]
	mov [aliveNumb], eax
	mov [SPMAIN], esp		; save esp for main
	mov ebx, [schedulerAddr]	; addr of the scheduler in the stack
	jmp do_resume
	
	




scheduler:
	mov ecx, [aliveDrones]		
	call checkWinner		; checking if only 1 drone is alive
	mov ebx, [roundCounter]		; ebx holds the round number , which will also be the co-routine addr in stack
	cmp byte [ecx + ebx], 1		; checking if drone is alive
	jne nextRound
	call resume			; resume control to drone co routine (ebx holds addr)
nextRound:
	inc dword [printCounter]
	mov eax, [K]			; eax holds number of rounds before printing
	cmp eax, [printCounter]
	jne moveCount
	mov dword [printCounter], 0	; reset print counter
	mov ebx, [printerAddr]		; setting ebx to resume printer
	call resume
moveCount:
	inc dword [moveCounter]		
	mov eax, [T]			; eax holds number of rounds before moving the target
	cmp eax, [moveCounter]
	jne roundRobin
	mov dword [moveCounter], 0	; reset move counter
	mov ebx, [targetAddr]		; setting ebx to resume target
	call resume
roundRobin:
	inc dword [roundCounter]	
	mov eax, [N]			 
	cmp eax, [roundCounter]		; checking if need to restart round robin
	jne scheduler			; not finished a "full" round robin
	mov dword [roundCounter], 0	; reset round robin counter
	inc dword [elimCounter]		; full cycle passed
	mov eax, [R]
	cmp eax, [elimCounter]
	jne scheduler			; no need to destroy yet
	mov dword [elimCounter], 0	; reset elimantion counter
	call destroyDrone		; destroy 1st drone
	call checkWinner		; check for a winner before trying to destroy a 2nd drone
	call destroyDrone		; destroy 2nd drone
	jmp scheduler			; next round
	
	




destroyDrone:
	mov dword [minTargets], 0x0FFFFFFF	; mins starts as highest int
	dec dword [aliveNumb]			; 1 less aliveDrone
	mov eax, [infoStack]
	mov ecx, [aliveDrones]
	mov ebx, 0
findDrone:
	cmp ebx, [N]
	je destroyEnd
	cmp byte [ecx + ebx], 1
	je checkDrone			; drone is alive 
	inc ebx				; next drone since drone is dead
	add eax, 20			; next drone info
	jmp findDrone
checkDrone:
	mov edx, [eax + 16]		; edx holds the amount of targets drone destroyed;
	inc ebx
	add eax, 20
	cmp [minTargets], edx	
	jl findDrone			; setting last lowest drone
	mov dword [minTargets], edx	; set new minimum 
	mov dword [eliminate], ebx	; save the drone ID with lowest destroyed targets currently
	dec dword [eliminate]		; we want a 0 based position for calculations

	
	jmp findDrone
destroyEnd:
	mov eax, [eliminate]		; eliminate holds the drone ID - 1
	mov byte [ecx + eax], 0		; "set" drone to dead
	ret
	




	
resume:
	pushfd				; push co routine flags
	pushad				; push co routine registers
	mov eax, [coRoutines]		; co routines stacks
	mov ecx, [CURR]			; get current co routine addr in stack
	mov [eax + ecx*8 + 4] , esp	; updating to current co routine stack position
do_resume:
	mov eax, [coRoutines]
	mov esp, [eax + ebx*8 + 4]	; co routine specific stack
	mov [CURR], ebx			; curr now holds the addr of the co routine in the stack
	popad				; restore registers for the co routine
	popfd				; restore flags for the co routine
	ret



checkWinner:
	mov eax, 0
	cmp dword [aliveNumb], 1
	je findWinner
	ret
findWinner:
	cmp byte [ecx + eax], 1
	je winner
	inc eax
	jmp findWinner
winner:
	inc eax
	push eax
	push format_winner
	call printf
	add esp,8
	call finishGame
	
	

finishGame:
	push dword [stacks]
	call free
	add esp, 4
	push dword [infoStack]
	call free
	add esp, 4
	push dword [coRoutines]
	call free
	add esp, 4
	push dword [aliveDrones]
	call free
	add esp, 4
	push 0
	call exit
	