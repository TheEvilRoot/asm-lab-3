.model small
.stack 100h
.data
	overflow_message db "Overflow occurred", 0Ah, 0Dh, '$'
	is_negative_result db 0
	is_zero_result	db 0
	
	division_value dw 0
	divisor_value dw 0
	division_result_int dw 0
	division_result_frac dw 0
.code

zero_set macro
	mov is_zero_result, 01h
endm

zero_unset macro
	mov is_zero_result, 00h
endm

overflow proc
	mov dx, offset overflow_message
	mov ah, 09h
	int 21h
	jmp exit	
	ret
overflow endp

is_negative proc
	push dx
	mov dx, ax
	shr dx, 15
	mov is_negative_result, dx
	pop dx
	ret
is_negative endp

is_zero proc
	cmp ax, 00h
	je is_zero_set
	jne is_zero_unset

	is_zero_set:
	zero_set
	jmp is_zero_ret
	
	is_zero_unset:
	zero_unset
	jmp is_zero_ret
	
	is_zero_ret:
	ret
is_zero endp

int_negative_divide proc
	push dx
	push cx
	
	mov dx, 00h
	int_negative_divide_for_loop:
		push ax
		add ax, bx
		call is_negative
		call is_zero
		pop ax
		
		mov cx, is_negative_result
		or cx, is_zero_result
		
		cmp cx, 00h
		je int_negative_divide_for_loop_end
		
		inc dx
		add ax, bx
		jmp int_negative_divide_for_loop
	int_negative_divide_for_loop_end:
	mov bx, dx

	pop cx
	pop dx
	ret
int_negative_divide endp

int_divide proc
	push dx

	cmp ax, 00h
	je int_divide_zero

	cmp bx, 00h
	je int_divide_zero

	call is_negative
	cmp is_negative_result, 01h
	je int_divide_negative

	cmp ax, bx
	jl int_divide_zero_int
	
	mov dx, 00h
	int_divide_for_while_loop:
		inc dx
		sub ax, bx
		cmp ax, bx
		jl int_divide_for_while_loop_end
		jmp int_divide_for_while_loop
	int_divide_for_while_loop_end:
	mov bx, dx
	jmp int_divide_ret

	int_divide_zero_int:
	mov bx, 00h
	jmp int_divide_ret

	int_divide_negative:
	call int_negative_divide
	jmp int_divide_ret

	int_divide_zero:
	mov ax, 00h
	mov bx, 00h
	jmp int_divide_ret
	
	int_divide_ret:
	pop dx
	ret
int_divide endp

frac_negative_divide proc 
	push cx
	push dx

	mov dx, 00h
	mov cx, 03h
	frac_negative_divide_for_loop:
		push cx
		cmp ax, 00h
		je frac_negative_divide_for_loop_end
		frac_negative_divide_while:
			push ax
			add ax, bx
			call is_negative
			call is_zero
			pop ax 	
			mov cx, is_negative_result
			xor cx, 01h
			or is_zero_result
			cmp cx, 01h
			jne frac_negative_divide_while_end
			push dx
			mov cx, 0ah
			imul cx
			pop dx
			push ax
			mov cx, 0ah
			mov ax, dx
			imul cx
			mov dx, ax
			pop ax
			jmp frac_negative_divide_while
		frac_negative_divide_while_end:
		frac_negative_divide_add_loop:
			push ax
			add ax, bx
			call is_negative
			call is_zero
			pop ax 	
			mov cx, is_negative_result
			or is_zero_result
			cmp cx, 01h
			jne frac_negative_divide_add_loop_end
			add ax, bx
			dec dx
			jmp frac_negative_divide_add_loop
		frac_negative_divide_add_loop_end:
		pop cx
	loop frac_negative_divide_for_loop
	
	frac_negative_divide_for_loop_end:
	mov ax, dx
	jmp frac_negative_divide_ret

	frac_negative_divide_ret:
	pop dx
	pop cx
	ret
frac_negative_divide endp

frac_divide proc
	push cx
	push dx

	cmp ax, 00h
	je frac_divide_ret_zero

	cmp bx, 00h
	je frac_divide_ret_zero

	call is_negative
	cmp is_negative_result, 01h
	je frac_divide_negative

	mov dx, 00h
	mov cx, 03h
	frac_divide_for_loop:
		push cx
		cmp ax, 00h
		je frac_divide_for_loop_end

		frac_divide_while_loop:
			cmp ax, bx
			jge frac_divide_while_loop_end
			push dx
			mov cx, 0ah
			imul cx
			pop dx
			push ax
			mov ax, dx
			mov cx, 0ah
			imul cx
			mov dx, ax
			pop ax
			jmp frac_divide_while_loop
		frac_divide_while_loop_end:
		frac_divide_sub_loop:
			cmp ax, bx
			jl frac_divide_sub_loop_end
			inc dx
			sub ax, bx
			jmp frac_divide_sub_loop
		frac_divide_sub_loop_end:
		pop cx
	loop frac_divide_for_loop

	frac_divide_for_loop_end:
	mov ax, dx
	jmp frac_divide_ret

	frac_divide_negative:
	call frac_negative_divide
	jmp frac_divide_ret

	frac_divide_ret_zero:
	mov ax, 00h
	jmp frac_divide_ret

	frac_divide_ret:
	pop dx
	pop cx
	ret
frac_divide endp
	
divide proc
	push ax
	push bx
	
	mov ax, division_value
	mov bx, divisor_value
	
	call int_divide
	mov division_result_int, bx

	mov bx, divisor_value

	call frac_divide
	mov division_result_frac, ax
	
	pop bx
	pop ax
	ret
divide endp

start:
mov ax, @data
mov ds, ax
mov es, ax
main:

exit:
mov ax, 4c00h
int 21h
end start
