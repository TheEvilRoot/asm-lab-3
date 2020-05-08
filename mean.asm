.model small
.stack 100h
.data
	overflow_message db "Overflow occurred", 0Ah, 0Dh, '$'
	is_negative_result dw 0
	is_zero_result	dw 0
	
	division_value dw 0
	divisor_value dw 0
	division_result_int dw 0
	division_result_frac dw 0

	numbers_count dw 0
	numbers_array dw numbers_count dup (0)
	numbers_sum dw 0

	numbers_mean_int dw 0
	numbers_mean_frac dw 0

	is_number_result dw 0
	
	buffer_max db 10
	buffer_size db 0
	buffer db buffer_max dup (0)
	
	parse_result dw 0
	parse_success dw 0

	print_int_value dw 0
	print_int_sign_flag dw 0

	print_float_int_value dw 0
	print_float_frac_value dw 0
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
		
		dec dx
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
			or cx, is_zero_result
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
			or cx, is_zero_result
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

sum proc
	push ax
	push bx
	push cx
	push dx
	push si

	mov dx, 00h
	mov si, offset numbers_array
	mov cx, numbers_count
	sum_for_loop:
		push cx
		mov ax, dx
		call is_negative
		push is_negative_result
		mov ax, [si]
		call is_negative
		push is_negative_result
		add ax, dx
		mov dx, ax
		call is_negative
		pop ax
		pop bx
		xor ax, bx
		cmp ax, 00h
		jne sum_for_loop_no_overflow
		xor bx, is_negative_result
		pop cx
		cmp bx, 00h
		je sum_for_loop_no_overflow
		call overflow
		sum_for_loop_no_overflow:
	loop sum_for_loop
	mov numbers_sum, dx
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
sum endp

mean proc
	push dx
	
	mov dx, numbers_sum
	mov division_value, dx

	mov dx, numbers_count
	mov divisor_value, dx

	call divide
	
	mov dx, division_result_int
	mov numbers_mean_int, dx

	mov dx, division_result_frac
	mov numbers_mean_frac, dx
	
	pop dx
	ret
mean endp

is_number proc
	cmp dl, '0'
	jl is_number_unset

	cmp dl, '9'
	jg is_number_unset

	jmp is_number_set

	is_number_unset:
	mov is_number_result, 00h
	jmp is_number_ret

	is_number_set:
	mov is_number_result, 01h
	jmp is_number_ret

	is_number_ret:
	ret
endp

parse_negative_int proc
	mov ax, 00h
	parse_negative_int_for_loop:
		mov dx, 00h
		mov dl, [si]
		call is_number
		cmp is_number_result, 01h
		jne parse_negative_int_invalid_char
		push cx
		sub dl, '0'
		mov cx, 0ah
		push dx
		imul cx
		pop dx
		sub ax, dx
		pop cx
		call is_negative
		cmp is_negative_result, 01h
		je parse_negative_for_loop_no_overflow
		call overflow
		parse_negative_for_loop_no_overflow:
		inc si
	loop parse_negative_int_for_loop
	mov parse_success, 01h
	mov parse_result, ax
	jmp parse_negative_int_ret

	parse_negative_int_invalid_char:
	mov parse_success, 00h
	mov parse_result, 00h
	jmp parse_negative_int_ret

	parse_negative_int_ret:
	ret
parse_negative_int endp

parse_int proc
	pusha
	mov si, offset buffer
	mov cx, 00h
	mov cl, buffer_size

	mov dx, 00h
	mov dl, [si]
	cmp dl, '-'
	je parse_int_negative

	mov ax, 00h
	parse_int_for_loop:
		mov dx, 00h
		mov dl, [si]
		call is_number
		cmp is_number_result, 01h
		jne parse_int_invalid_char
		; multiply ax by 10
		; and add dl to it
		; why the fuck am i multiplying dx by 10???
		push cx
		sub dl, '0'
		mov cx, 0ah
		push dx
		imul cx
		pop dx
		add ax, dx
		pop cx
		call is_negative
		cmp is_negative_result, 00h
		je parse_for_loop_no_overflow
		call overflow
		parse_for_loop_no_overflow:
		inc si
	loop parse_int_for_loop
	mov parse_success, 01h
	mov parse_result, ax
	jmp parse_int_ret

	parse_int_negative:
	inc si
	dec cx
	call parse_negative_int
	jmp parse_int_ret

	parse_int_invalid_char:
	mov parse_success, 00h
	mov parse_result, 00h
	jmp parse_int_ret

	parse_int_ret:
	popa
	ret
parse_int endp

read_buffer proc
	pusha
	mov dx, offset buffer_max
	mov ah, 0ch
	mov al, 0ah
	int 21h
	popa
	ret
endp

print_char proc
	pusha
	mov ax, 00h
	mov ah, 02h
	int 21h
	popa
	ret
print_char endp

print_int proc
	pusha
	mov ax, print_int_value
	call is_negative
	mov cx, is_negative_result
	and cx, print_int_sign_flag

	cmp cx, 00h
	jne print_int_set_minus
	jmp print_int_start

	print_int_set_minus:
	mov dx, 00h
	mov dl, '-'
	call print_char
	jmp print_int_start
	
	print_int_start:
	mov dx, 00h
	mov cx, 00h
	print_int_while_loop:
		mov bx, 0ah
		call int_divide
		push bx
		call is_negative
		cmp is_negative_result, 01h
		je print_int_put_negative_int
		
		jmp print_int_put_int
			
		print_int_put_negative_int:
		mov bx, ax
		mov ax, 00h
		sub ax, bx
		jmp print_int_put_int

		print_int_put_int:
		add ax, '0'
		mov dx, ax
		pop bx
		push dx
		inc cx
		mov ax, bx
		call is_zero
		cmp ax, 00h
		je print_int_while_loop_end
		jmp print_int_while_loop
	print_int_while_loop_end:
	print_int_put_from_stack:
		pop dx
		call print_char 
	loop print_int_put_from_stack	
	print_int_ret:
	popa
	ret
print_int endp

print_float proc
	pusha
	mov dx, print_float_int_value
	mov print_int_value, dx
	 
	mov print_int_sign_flag, 01h
	call print_int
	mov dx, ','
	call print_char
	
	mov dx, print_float_frac_value
	mov print_int_value, dx
	mov print_int_sign_flag, 00h
	call print_int
	mov print_int_sign_flag, 01h
	popa
	ret
print_float endp

handle_input proc
	pusha
	mov cx, numbers_count
	mov si, offset numbers_array
	
	handle_input_for_loop:
		call read_buffer
		call parse_int
		cmp parse_success, 01h
		je handle_input_success:
		jne handle_input_failed

		handle_input_success:
		mov ax, parse_result
		mov [si], ax
		add si, 2
		jmp handle_input_continue

		handle_input_failed:
		int 3h
		jmp handle_input_continue

		handle_input_continue:
	loop handle_input_for_loop

	popa
	ret
handle_input endp

start:
mov ax, @data
mov ds, ax
mov es, ax
main:
call read_buffer
call parse_int
jmp exit
mov numbers_count, 03h
call handle_input
call sum
call mean
mov dx, numbers_sum
mov print_int_value, dx
mov print_int_sign_flag, 01h
call print_int

mov dx, numbers_mean_int
mov print_float_int_value, dx

mov dx, numbers_mean_frac
mov print_float_frac_value, dx 
call print_float
exit:
mov ax, 4c00h
int 21h
end start
