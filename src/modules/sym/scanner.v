module sym

[if debug]
fn log<T>(msg T){
	println(msg)
}

struct ScannerState{
mut:
	//第几个字
	word_pos int
	//第几个byte
	byte_pos int
	//第几行
	line int
	//本行开始之前一共有多少个字
	prev_line_word_pos int
	//本行开始之前一共有多少byte
	prev_line_byte_pos int
	//是否结束
	is_end bool
}

struct Scanner{
	text string
mut:
	//第几个字
	word_pos int
	//第几个byte
	byte_pos int
	//第几行
	line int
	//本行开始之前一共有多少个字
	prev_line_word_pos int
	//本行开始之前一共有多少byte
	prev_line_byte_pos int
	//是否结束
	is_end bool
	//pushd popd 保存和还原状态
	stack []ScannerState
	//上一个状态
	prev_state ScannerState
}

fn new_scanner(text string)Scanner{
	return Scanner{
		text:text
		stack:[]ScannerState{cap:1}
	}
}

fn (mut s Scanner) scan()?[]byte{
	s.prev_state.word_pos = s.word_pos
	s.prev_state.byte_pos = s.byte_pos
	s.prev_state.line = s.line
	s.prev_state.prev_line_word_pos = s.prev_line_word_pos
	s.prev_state.prev_line_byte_pos = s.prev_line_byte_pos
	s.prev_state.is_end = s.is_end

	if s.byte_pos >= s.text.len{
		s.is_end = true
		return []byte{}
	}
	return s.get_utf8_word()
}

[inline]
fn (mut s Scanner) get_utf8_word()?[]byte{
	str:=s.text
	pos:=s.byte_pos

	//pos位置check
	if str.len == 0 {
		log('utf8str_to_unicodepoint 0001')
		return error('Input string length = 0.')
	}

	if pos >= str.len || pos < 0{
		log('utf8str_to_unicodepoint 0002')
		return error('Position < string.len.')
	}

	//获取先头1位和2位
	first_bit := byte(str[pos] >> 7)

	//线头1位=0 ascii字符
	if first_bit == 0b0 {
		s.byte_pos++
		s.word_pos++

		if str[pos] == `\n`{
			s.line++
			s.prev_line_word_pos = s.word_pos
			s.prev_line_byte_pos = s.byte_pos
		}

		return [str[pos]]
	}

	//获取多字节字的 123 1234 12345 位
	bit_123 := byte(str[pos] >> 5)
	bit_1234 := byte(str[pos] >> 4)
	bit_12345 := byte(str[pos] >> 3)

	mut word := []byte{}
	//为2byte的utf8字时
	if bit_123 == 0b00000110{
		if str.len - pos < 2{
			log('utf8str_to_unicodepoint 0004')
			return error('This code point requires at least 2 bytes.')
		}
		word << str[pos]
		word << str[pos+1]
		s.byte_pos+=2
		s.word_pos++	
	//为3byte的utf8字时
	}else if bit_1234 == 0b00001110{
		if str.len - pos < 3{
			log('utf8str_to_unicodepoint 0005')
			return error('This code point requires at least 3 bytes.')
		}
		word << str[pos]
		word << str[pos+1]
		word << str[pos+2]
		s.byte_pos+=3
		s.word_pos++	
	//为4byte的utf8字时
	}else if bit_12345 == 0b00011110{
		if str.len - pos < 4{
			log('utf8str_to_unicodepoint 0006')
			return error('This code point requires at least 4 bytes.')
		}
		word << str[pos]
		word << str[pos+1]
		word << str[pos+2]
		word << str[pos+3]
		s.byte_pos+=4
		s.word_pos++	
	}else{
		//大于4byte的utf8字暂时不支持
		//目前最大应该为 0x10FFFF 但多处理一些应该也没有问题吧
		log('utf8str_to_unicodepoint 0007')
		return error('Code point > U+1FFFFF.')
	}

	return word
}

fn (mut s Scanner) pushd(){
	s.stack << ScannerState{
		word_pos:s.word_pos
		byte_pos:s.byte_pos
		line:s.line
		prev_line_word_pos:s.prev_line_word_pos
		prev_line_byte_pos:s.prev_line_byte_pos
		is_end:s.is_end
	}
}

fn (mut s Scanner) popd(){
	stack := s.stack.pop()
	s.word_pos = stack.word_pos
	s.byte_pos = stack.byte_pos
	s.line = stack.line
	s.prev_line_word_pos = stack.prev_line_word_pos
	s.prev_line_byte_pos = stack.prev_line_byte_pos
	s.is_end = stack.is_end
}

fn (mut s Scanner) clean_stack(){
	l := s.stack.len
	for i:=0;i<l;i++{
		s.stack.pop()
	}
}

fn (mut s Scanner) prev_scan(){
	s.word_pos = s.prev_state.word_pos
	s.byte_pos = s.prev_state.byte_pos
	s.line = s.prev_state.line
	s.prev_line_word_pos = s.prev_state.prev_line_word_pos
	s.prev_line_byte_pos = s.prev_state.prev_line_byte_pos
	s.is_end = s.prev_state.is_end
}