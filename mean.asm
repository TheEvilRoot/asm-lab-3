.286
.model small
.stack 100h
.data
	overflow_message db "Overflow occurred", 0Ah, 0Dh, '$'
	new_line_message db 0Ah, 0Dh, '$'
	invalid_value_message db "Invalid value. Try again...", 0Ah, 0Dh, '$'
	count_prompt_message db "Enter count of elements: ", '$'
	count_invalid_message db "Count must be in range (0, 32]", 0Ah, 0Dh, '$'
	array_prompt_start db "Enter ", '$'
	array_prompt_end db " numbers: ", 0Ah, 0Dh, '$'
	mean_message db "Mean value = ", '$'
	sum_message db "Sum = ", '$'  

	is_negative_result dw 0
	is_zero_result	dw 0
	
	division_value dw 0
	divisor_value dw 0
	division_result_int dw 0
	division_result_frac dw 0

	numbers_count_valid dw 0

	numbers_count dw 0
	numbers_array dw 30 dup (0)
	numbers_sum dw 0

	numbers_mean_int dw 0
	numbers_mean_frac dw 0

	is_number_result dw 0
	
	buffer_max db 10
	buffer_size db 0
	buffer db 10 dup (0)
	
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

new_line proc
	pusha
	mov dx, offset new_line_message
	mov ax, 00h
	mov ah, 09h
	int 21h
	popa
	ret
new_line endp

invalid_value proc
	pusha
	mov dx, offset invalid_value_message
	mov ax, 00h
	mov ah, 09h
	int 21h
	popa
	ret
invalid_value endp

count_prompt proc
	pusha
	mov dx, offset count_prompt_message
	mov ax, 00h
	mov ah, 09h
	int 21h
	popa
	ret
count_prompt endp

count_error proc
	pusha
	mov dx, offset count_invalid_message 
	mov ax, 00h
	mov ah, 09h
	int 21h
	popa
	ret
count_error endp

array_prompt proc
	pusha
	mov dx, offset array_prompt_start
	mov ax, 00h
	mov ah, 09h
	int 21h
	mov dx, numbers_count
	mov print_int_value, dx
	mov print_int_sign_flag, 01h
	call print_int
	mov dx, offset array_prompt_end
	mov ax, 00h
	mov ah, 09h
	int 21h
	popa
	ret
array_prompt endp

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
		cmp ax, 00h
		je frac_negative_divide_for_loop_end
		push cx
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
		cmp ax, 00h
		je frac_divide_for_loop_end
		push cx
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
		pop cx
		cmp ax, 00h
		jne sum_for_loop_no_overflow
		xor bx, is_negative_result
		cmp bx, 00h
		je sum_for_loop_no_overflow
		call overflow ; when sum overflow occurrs just terminate
		sum_for_loop_no_overflow:
		add si, 2
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
		sub dl, '0'
		cmp ax, 00h
		jne parse_negative_int_for_loop_continue
		cmp dl, 00h
		jne parse_negative_int_for_loop_continue
		jmp parse_negative_for_loop_no_overflow
		parse_negative_int_for_loop_continue:
		push cx
		mov cx, 0ah
		push dx
		imul cx
		jo parse_negative_for_loop_overflow_occurred
		pop dx
		sub ax, dx
		pop cx
		call is_negative
		cmp is_negative_result, 01h
		je parse_negative_for_loop_no_overflow
		jne parse_negative_for_loop_overflow_occurred_im
		parse_negative_for_loop_overflow_occurred:
		pop dx
		pop cx
		parse_negative_for_loop_overflow_occurred_im:
		jmp parse_negative_int_invalid_char
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
		jo parse_for_loop_overflow_occurred
		pop dx
		add ax, dx
		pop cx
		call is_negative
		cmp is_negative_result, 00h
		je parse_for_loop_no_overflow
		jne parse_for_loop_overflow_occurred_im 
		parse_for_loop_overflow_occurred:
		pop dx
		pop cx
		parse_for_loop_overflow_occurred_im:
		jmp parse_int_invalid_char ; was call overflow
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

	mov ax, print_float_int_value
	call is_negative

	mov cx, is_negative_result

	mov ax, print_float_frac_value
	call is_negative

	or cx, is_negative_result

	cmp cx, 00h
	jne print_float_minus
	jmp print_float_continue

	print_float_minus:
	mov dx, '-'
	call print_char
	jmp print_float_continue

	print_float_continue:
	mov dx, print_float_int_value
	mov print_int_value, dx
	
	mov print_int_sign_flag, 00h
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
		call new_line
		cmp parse_success, 01h
		je handle_input_success
		jne handle_input_failed

		handle_input_success:
		mov ax, parse_result
		mov [si], ax
		add si, 2
		jmp handle_input_continue

		handle_input_failed:
		inc cx
		call invalid_value
		jmp handle_input_continue

		handle_input_continue:
	loop handle_input_for_loop

	popa
	ret
handle_input endp

is_count_valid proc
	pusha
	mov ax, numbers_count
	call is_negative
	
	cmp is_negative_result, 00h
	jne is_count_valid_invalid

	cmp ax, 00h
	je is_count_valid_invalid

	cmp ax, 20h
	jg is_count_valid_invalid

	jmp is_count_valid_ok

	is_count_valid_ok:
	mov numbers_count_valid, 01h
	jmp is_count_valid_ret

	is_count_valid_invalid:
	mov numbers_count_valid, 00h
	jmp is_count_valid_ret

	is_count_valid_ret:		
	popa
	ret
is_count_valid endp

handle_count proc
	pusha
	handle_count_loop:
		call count_prompt
		call read_buffer
		call parse_int
		call new_line
		mov dx, parse_result
		mov numbers_count, dx
		mov cx, parse_success
		call is_count_valid
		and cx, numbers_count_valid
		cmp cx, 00h
		jne handle_count_ret
		call count_error
		jmp handle_count_loop	
	handle_count_ret:
	
	popa
	ret
handle_count endp

print_sum proc
	pusha
	mov dx, offset sum_message
	mov ax, 00h
	mov ah, 09h
	int 21h
	mov dx, numbers_sum
	mov print_int_value, dx
	mov print_int_sign_flag, 01h
	call print_int
	call new_line
	popa
	ret
print_sum endp

print_mean proc
	pusha
	mov dx, offset mean_message
	mov ax, 00h
	mov ah, 09h
	int 21h
	mov dx, numbers_mean_int
	mov print_float_int_value, dx
	mov dx, numbers_mean_frac
	mov print_float_frac_value, dx 
	call print_float
	call new_line
	popa
	ret
print_mean endp

start:
mov ax, @data
mov ds, ax
mov es, ax
main:
call handle_count
call new_line
call array_prompt
call handle_input
call sum
call mean
call new_line
call print_sum
call print_mean
exit:
mov ax, 4c00h
int 21h
end start
