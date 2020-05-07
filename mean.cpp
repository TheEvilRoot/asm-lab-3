#include <iostream>
#include <string>
#include <stack>

#define int int16_t

void overflow() {
	std::cout << "Overflow occurred" << std::endl;
	exit(0);
}

// possible overflow situations:
//  - sum (fixed)
//  - division (no, it's not)
//  - parsing (fixed)

struct result {
	int ax;
	int bx;
};

bool is_negative(int value) {
	return value < 0;
}

bool is_zero(int value) {
	return value == 0;
}

// assume that all precautions has been taken already
result int_negative_divide(int value, int divisor) {
	int result = 0;
	while (true) {
		if (is_negative(value + divisor) || is_zero(value + divisor)){// does -n + m can cause overflow?
			result--;
			value += divisor;
		} else break;
	}
	return { result, value };
}
// result and left are negative or 0

// assume that divisor is always positive
// value can be positive or negative
result int_divide(int value, int divisor) {
	if (value == 0 || divisor == 0) {
		return  { 0, 0 };
	}

	if (is_negative(value)) {
		return int_negative_divide(value, divisor);
	}

	if (value < divisor) {
		return { 0, value };
	}

	int result = 0;
	while (value >= divisor) {
		result++;
		value -= divisor;
	}

	return { result, value };
}
// result is negative only if value is negative


// assume that all precautions has been taken already
int frac_negative_divide(int left, int divisor) {
	int result = 0;
	for (int i = 0; i < 3; i++) {
		if (left == 0) {
			return result;
		}
		// do I actually need true? or false?
		// -n + m >= 0 if |n| <= m
		// -n + m < 0  if |n| > m
		while (!is_negative(left + divisor) || is_zero(left + divisor)) { // does -n + m can cause overflow? no
			left *= 10; // signed mult
			result *= 10; // signed mult too
		}
		// what do i need here?
		// while |left| >= divisor
		// => -left + divisor <= 0
		while (is_negative(left + divisor) || is_zero(left + divisor)) {
			left += divisor;
			result--;
		}
	}	
	return result;	
}
// always return negative result

// assume that divisor is always positive too
int frac_divide(int left, int divisor) {
	if (left == 0 || divisor == 0) {
		return 0;
	}	

	if (is_negative(left)) {
		return frac_negative_divide(left, divisor);
	}

	int result = 0;
	for (int i = 0; i < 3; i++) {
		if (left == 0) {
			return result;
		}
		while (left < divisor) {
			left *= 10;
			result *= 10;
		}
		while (left >= divisor) {
			result++;
			left -= divisor;
		}
	}

	return result;
}
// result is negative if left is negative

// assume that divisor is always positive
result divide(int value, int divisor) {
	auto [ax, bx] = int_divide(value, divisor);
	auto frac = frac_divide(bx, divisor);
	return { ax, frac };
}
// int and frac part of result has same sign.
// if result is negative they are negative too

// overflow condition on a + b \in [-32768; 32767]
// is_negative(a) and is_negative(b) => not is_negative(a + b) => overflow
// not is_negative(a) nor is_negative(b) => is_negative(a + b) => overflow
// is_negative(a) and not is_negative(b) => no overflow cond.
// not is_negative(a
int sum(int *arr, int size) {
	int s = 0;
	for (int i = 0; i < size; i++) {
		auto sum_negative = is_negative(s);
		auto i_negative = is_negative(arr[i]);
		s += arr[i];
		if (sum_negative && i_negative && !is_negative(s)) {
			overflow();	
		}
		if(!sum_negative && !i_negative && is_negative(s)) {
			overflow();
		}
	}
	return s;
}

result mean(int s, int count) {
	return divide(s, count);
}

bool is_number(char c) {
	return c >= '0' && c <= '9';
}

int parse_negative_int(const char *buffer, int size) {
	int value = 0;
	for (int i = 0; i < size; i++) {
		if (is_number(buffer[i])) {
			int n = buffer[i] - '0';
			value *= 10; // signed mult
			value -= n;
			if (!is_negative(value)) {
				overflow();
			}
		}
	}
	return value;
}

int parse_int(const char *buffer, int size) {
	if (buffer[0] == '-') {
		return parse_negative_int(buffer + 1, size - 1); 
	}
	int value = 0;
	for (int i = 0; i < size; i++) {
		if (is_number(buffer[i])) {
			int n = buffer[i] - '0';
			value *= 10;
			value += n;
			if (is_negative(value)) {
				overflow();
			}
		}
	}
	return value;
}

void print_char(char chr) {
	std::cout << chr;
}

void print_negative_num(int value) {
	print_char(0 - value + '0');
}

void print_int(int value, int need_sign = true) {
	if (is_negative(value) && need_sign) {
		print_char('-');
	}
	std::stack<char> stack;
	int count = 0;
	while (true) {
		auto [ax, bx] = int_divide(value, 10);
		value = ax;
		if (is_negative(bx)) {
			stack.push(0 - bx + '0');
		} else {
			stack.push(bx + '0');
		}
		count++;
		if (is_zero(value)) {
			break;
		}
	}
	for (int i = 0; i < count; i++) {
		print_char(stack.top());
		stack.pop();	
	}
}

void print_float(int i, int f) {
	print_int(i);
	print_char(',');
	print_int(f, false);
}

int32_t main() {
	int *arr = new int[3];
	for (int i = 0; i < 3; i++){
		std::string str;
		std::getline(std::cin, str);
		arr[i] =  parse_int(str.c_str(), str.length());
	}
	auto [ax, bx] = mean(sum(arr, 3), 3);
	print_float(ax, bx);
	print_char('\n');	
	return 0;
}
