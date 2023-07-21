section .rodata
	format_target: db "%.2lf, %.2lf", 10, 0	
	format_drone:  db "%d, %.2lf, %.2lf, %.2lf, %.2lf, %d", 10, 0

section .text
	align 16
	global printer
	extern x
	extern y
	extern N
	extern resume
	extern schedulerAddr
	extern infoStack
	extern aliveDrones
	extern printf 




	
printer:
	call printTarget
	call printDrones
	mov eax, dword [schedulerAddr]
	call resume
	jmp printer
	



printTarget:
	finit
	fld dword [y]
	sub esp, 8
	fstp qword [esp]
	fld dword [x]
	sub esp, 8
	fstp qword [esp]
	push format_target
	call printf
	add esp, 20
	ret



printDrones:
	mov ebx, 1			; for the id
	mov eax, [infoStack]
	mov edx, [aliveDrones]
	mov ecx, [N]
printLoop:
	cmp byte [edx], 0 		; if drone is dead
	je loopNext			; go to next drone
	call printDrone
loopNext:
	inc ebx				; next drone position
	inc edx				; next drone in aliveDrones
	add eax, 20			; each info has size of 20 bytes, move to the next
	loop printLoop 
	ret


printDrone:
	pushad
	push dword [eax + 16]		; number of targets drone destroyed
	finit
	fld dword [eax + 12]		; drone angle
	sub esp, 8
	fstp qword [esp]
	fld dword [eax + 8]		; drone speed
	sub esp, 8
	fstp qword [esp]
	fld dword [eax + 4]		; y coord
	sub esp, 8
	fstp qword [esp]
	fld dword [eax]			; x coord
	sub esp, 8
	fstp qword [esp]
	push ebx
	push format_drone
	call printf
	add esp, 44
	popad
	ret
	
	
	


