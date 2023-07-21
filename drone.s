BOARD EQU 100


section .data
	zero:		dd 0
	sixty:		dd 60
	oneEighty:	dd 180
	threeSixty:	dd 360
	angle:		dd 0
	wrapSize:	dd 0
	maxSpeed:	dd 255
	distance:	dd 0
	distanceX:	dd 0
	distanceY:	dd 0
	wrapDroneX:	dd 0
	wrapDroneY:	dd 0
	wrapTargetX:	dd 0
	wrapTargetY:	dd 0	
		
section .text
	align 16
	global drone
	extern resume
	extern infoStack
	extern getRandomNumb
	extern x
	extern y
	extern d
	extern destroyed
	extern roundCounter
	extern targetAddr
	extern schedulerAddr
	extern seed
	extern scaled_seed
	extern scale
	extern printf 
	extern malloc 
	extern calloc 
	extern free 
	extern sscanf

drone:
	call getAngle			; generate new angle
	call getNewPosition		; move drone to a new location based on its info
droneLoop:
	call setParam			; set new angle and wrap coords
	call mayDestroy			; try to destroy without wrap around // 5
	add dword [wrapDroneX], BOARD
	add dword [wrapDroneY], BOARD
	call mayDestroy			; try to destroy with wrap to left and bottom  // 7
	add dword [wrapTargetX], BOARD
        call mayDestroy			; try to destroy with wrap to bottom  // 8
        add dword [wrapTargetX], BOARD
        call mayDestroy			; try to destroy with wrap to right and bottom  // 9
        add dword [wrapTargetY], BOARD
        call mayDestroy			; try to destroy with wrap to right  // 6
        add dword [wrapTargetY], BOARD
        call mayDestroy			; try to destroy with wrap to right and top  // 3
        sub dword [wrapTargetX], BOARD
        call mayDestroy			; try to destroy with wrap to top  // 2
        sub dword [wrapTargetX], BOARD
        call mayDestroy			; try to destroy with wrap to left and top  // 1
        sub dword [wrapTargetY], BOARD
        call mayDestroy			; try to destroy with wrap to left  // 4

	call getAngle
	call getNewPosition,
	mov dword [destroyed], 0	; target was not destroyed
	mov ebx, [schedulerAddr]
	call resume
	jmp droneLoop
destroy:
	inc dword [eax + 16] 		; inc number of drones destroyed
	mov dword [destroyed], 1	; set target to destroyed, thus being called by a drone
	mov ebx, [targetAddr]		; back to target
	call resume
	jmp drone




getAngle:
	mov dword [scale], 120		; between -60 and 60
	call getRandomNumb		; generate random angle
	mov eax, 20			; size of each drone in the info stack
	mov ecx, [roundCounter]		; roundCounter is also the drone ID - 1
	mul ecx				; get the position for the current drone info in eax
	add eax, [infoStack]		; eax now holds the position for the drone info
	mov ecx, [scaled_seed]
	mov [angle], ecx
	finit				; init float register
	fld dword [eax + 8]		; current angle, in the info stack	
	fadd dword [angle]		; load angle
	fisub dword [sixty]		; dec by 60 to get angle between -60 and 60
	mov ecx, [threeSixty]
	mov [wrapSize],	ecx
	call wrap			; wrap around edges
	fstp dword [angle]		; not yet changing current drone angle


getNewPosition:
	finit
	fldpi				; loading pie to calculate angle in radians
	fmul dword [eax + 8]		; multiply by current angle
	fidiv dword [oneEighty]		; divide by 180 to get angle in radians
	fsin				; get sin in stack
	fmul dword [eax + 12]		; multiply sin by speed
	fadd dword [eax]		; add x's current location
	mov ecx, 100
	mov [wrapSize], ecx
	call wrap
	fstp dword [eax]		; store new x location
	fldpi
	fmul dword [eax + 8]
	fidiv dword[oneEighty]
	fcos
	fmul dword [eax + 12]		; multiply cos by speed
	fadd dword [eax + 4]		; add y's current location
	call wrap
	fstp dword [eax + 4]		; store new y location
	ret
		
		


	
wrap:	
	fild dword [wrapSize]
	fcomip				
	ja wrapMinus
	fisub dword [wrapSize]
	jmp wrap
wrapMinus:
	fild dword [zero]
	fcomip
	jb wrapEnd
	fiadd dword [wrapSize]
	jmp wrapMinus
wrapEnd:
	ret


setParam:
	mov ecx, [angle]
	mov [eax + 8], ecx		; store new angle
	mov ecx, [d]			; ecx holds distance
	mov [distance], edx		; save distance 
	mov ecx, [x]			
	mov [wrapTargetX], ecx		; save target X so we can wrap it if needed
	mov ecx, [y]
	mov [wrapTargetY], ecx		; save target Y so we can wrap it if needed
	mov ecx, [eax]			
	mov [wrapDroneX], ecx		; save drone X so we can wrap it if needed
	mov ecx, [eax + 4]			
	mov [wrapDroneY], ecx		; save drone Y so we can wrap it if needed
	ret




mayDestroy:				; will calculate  sqrt ((DroneX - TargetX)^2 + (DroneY - TargetY)^2) for distance	
	finit
	fld dword [wrapTargetX]		; target x coords with wrap
	fsub dword [wrapDroneX]		; drone x coords with wrap
	fst dword [distanceX]		; TargetX - DroneX
	fld dword [wrapTargetY]		; target y coords with wrap
	fsub dword [wrapDroneY]	 	; donre y coords with wrap
	fst dword [distanceY]		; TargetY - DroneY
	fmul dword [distanceY]		; (TargetY - DroneY)^2
	fstp dword [distanceY]		
	fmul dword [distanceX]		; (TargetX - DroneX)^2		
	fadd dword [distanceY]		; (TargetX - DroneX)^2 + (TargetY - DroneY)^2 
	fsqrt				; sqrt (TargetX - DroneX)^2 + (TargetY - DroneY)^2 
	fild dword [d]		
	fcomip
	jae canDestroy			; close enough to destroy
	ret
canDestroy:
	pop edx				; poping return adress, not needed
	jmp destroy	
