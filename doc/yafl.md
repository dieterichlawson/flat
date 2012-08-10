# YAFL (yet another format language)
Other possible names:

- Flatland

- YAPL (yet another parsing language)

- FlatUnformatter

- ??

## Guiding Principles

- YAFL should make it stupidly easy to parse fixed-width files
	- Fixed width files are the priority, variable width features will be added where is easy to do so.
	- Again, variable-width delimited files are not the priority. It's easy to fall into this trap.
- Format strings should be able to line up with the lines that they parse. This makes the format strings self documenting and easy to understand. TODO: EXAMPLE
- The format tokens should be as unsurprising as possible - take evidence from `printf`, `scanf`, `strftime`,`pack`, the common log format, and avro type names.
- When at all possible formatting specifics should not be made explicit. E.g. 'a 7-character float' is preferrable to 'a float with 2 digits before the decimal point and 5 digits afterwards'. 'A date' is preferrable to '4 year digits followed by two month digits …' LIGHT PREDICTABLE MAGIC
	- The corollary to this is that the user should be able to make formatting choices explicit if necessary.
- If a record does not parse correctly, an error should be thrown. Things should not fail silently or just return empty values on error.
- You shouldn't have to look at regular expressions unless you want to.
- There should not be %'s everywhere

## General Stuff

Format lines are composed of tokens, which are in turn composed of types and widths . The types are defined below and correspond to the commonly-used data types. The widths are numbers that represent the width of the type in characters. Bare types represent a width of 1, e.g. `s` matches a single character.

For example, the token `i5` matches a 5-digit integer. `s10` matches a 10-character string.

To use YAFL, you first write your format string. Then, YAFL will create a parser for you based on your format string which will accept lines and split out lists of values. e.g.

	format = "i4  i4  s10  d10"
	parser = YAFL.new(format)
	flat_file = File.open("flat_file.txt")
	flat_file.each_line do |line|
		values = parser.parse(line) 
		# at this point values will be something like [1234, 5678, 'helloworld', 2012-08-06 13:47:18 -0500]
		... do something with the values ...
	end

## Types

###`i` - integer (signed or unsigned)

You can have a leading `+` or `-`, but you should include the sign character in your 'count'. e.g. `+124255` should be matched as i7.

---

### `f` - floating (or fixed) point number

Can include a leading `+` or `-`, but sign characters should be included in the character count. 

`f7` represents a float 7 characters in length. The 7 characters could be any of the following:

- `1.234567` - _fixed point_
- `1.234e56` - _scientific notation_
- `1.234E56`
- `1.234e-5` - _negative exponent_
- `12.34e56` - _2 digits before the decimal point_
 
_Might_ want at some point:

- `1.2x10^2`
- `1.2X10^2`
- `1.2*10^2`
- `1.2*23^2` - _non-standard base_

_Might_ want at some point:

If your format is more complex (e.g. delimited in some way) it is also possible to define your own float format. Your format must have one of each of the following components:

- `s` - significand
- `b` - base
- `e` - exponent

---

### `s` - string

Can be any sequence of characters, including whitespace, tabs, newlines, etc…

---

### `x` - hex
	
Can have a leading `0x` or not, but you should include the `0x` in your character count.

Can only include the characters `0-9 a-f A-F`

---

### `b` - boolean

Default true values (case insensitive): `true, tru, tr, t, 1, yes, ye, y`

Default false values (case insensitive): `false, fals, fal, fa, f, 0, no, n`

---

### `d` - date

If you think your date can be understood by [chronic](https://github.com/mojombo/chronic/), then just append the number of characters. This will work:
		
	08/14/1989
	d10
		
This will not:

	08 14 1989
	d10

To fix this, you can define your own format using strftime formatting characters. e.g.

	  08 14 1989
	d:mm dd YYYY:

---

`_` - ignore a character

- `_*` to ignores 0 or more whitespace characters
- `_+` to ignores 1 or more whitespace characters

## Modifiers

`*` - 0 or more
`+` - 1 or more

## Whitespace

Whitespace parsing is flexible, with the goal of 'doing the right thing' without too much prodding. YAFL assumes that input tokens will be separated by _at most_ one whitespace character in input lines. For example, all of these format strings matches correctly, returning `[1234, 5678]`:
	
	1234 5678
	i4 i4
	i4i4
		
Multiple concatenated whitepace tokens in the format string are assumed to represent _at most_ a single whitespace character in the input string. For example, this matches correctly:
	
	1234 5678
	i4   i4		
	
But this also returns `[1234,5678]`:
	
	12345678
	i4  i4
			
By default, multiple whitepsace delimiters are not consumed at once. For example, the following integers are separated by two tabs:
	
	1234		5678		9012
	i4          i4          i4
	
In this case, the returned values would be `[1234, '', 5678]`. To match multiple delimiters between tokens, you must explicitly consume the characters, e.g.:
	
	1234		5678		9012
	i4    __	i4	   __	i4
	
To allow for a variable amount of whitespace between tokens, use `_*` (0 or more) or `_+` (1 or more) which will consume all whitespace until the next non-whitepace character. e.g.

	i4 _* i4 _* i4
		
will successfully return `[1234,5678,9012]` for all of the following:
		
	1234   5678 1234
	123456789012
	1234 5678 9012
	1234			5678	9012

Note that `_` consumes one character, no matter what that character is, but `_*` and `_+` only consume whitespace.

### Sub-syntaxes

Also note that these whitespace rules do not apple in the sub-syntaxes for floats and dates. In those sub-syntaxes, whitespace is significant in the sense that those characters are ignored. For example:

	  1.234|12|3453
	  1.234 12 3453
	  1.234#12!3453
	f:sssss bb eeee:


all parse correctly as `1.234x12^3453`, but these does not:

	  1.234  12 3453
	  1.234123453
	f:sssss bb eeee:
	
Weirdly enough, the following will parse 'correctly', in the sense that it returns `1.234x12^3453`. `0` is being used as a spacer and is ignored:

	  1.23401203453
	f:sssss bb eeee:

## Numbers

Leading 0s are ignored when parsing numbers, unless they are significant like in the case of floats, e.g. `0.005e10`.

Nan and infinity are allowed in both floats and ints. By default, any casing of `nan` represents `nan`, and any casing of `infinity` and `inf` represent infinity.

## Problems

- The sub-syntax syntax is problematic for the alignment of format strings with the lines they match. For example, assume that the following record represents inches of rainfall (15) on a specific date (08/14/1989):

		15 08 14 1989
	    i2d:mm dd YYYY:
	    
Alignment is impossible.

- What about nil values?

- What about variable width records?

- What about records that specify their width somewhere earlier?

- Optional records?
	    
## Questions
- Why shouldn't we allow `iiiii` == `i5` ? 
	- A: because if you have a line like this: `1248582929593` but it's made up of multiple integer fields, it would be impossible to tell them apart. i.e. :
			
			1248582929593
			iiiiiiiiiiiii
		
		vs.
		
			1248582929593
			i5   i2i6
			
	- However, this rule is broken in the case of all 'sub-syntaxes' like dates and floats, which operate like strftime and scanf. e.g. `YYYY` is a 4-digit year. It's best to think of `YYYY` and `YY` as their own tokens instead of concatenations of the `Y` token.
	
#Appendices

##Strftime

<table>
  <tbody>
    <tr><th>specifier</th><th>Replaced by</th><th>Example</th></tr>
    <tr><td><tt>%a</tt></td><td>Abbreviated weekday name *</td><td><tt>Thu</tt></td></tr>
    <tr><td><tt>%A</tt></td><td>Full weekday name * </td><td><tt>Thursday</tt></td></tr>
    <tr><td><tt>%b</tt></td><td>Abbreviated month name *</td><td><tt>Aug</tt></td></tr>
    <tr><td><tt>%B</tt></td><td>Full month name *</td><td><tt>August</tt></td></tr>
    <tr><td><tt>%c</tt></td><td>Date and time representation *</td><td><tt>Thu Aug 23 14:55:02 2001</tt></td></tr>
    <tr><td><tt>%d</tt></td><td>Day of the month (<tt>01-31</tt>)</td><td><tt>23</tt></td></tr>
    <tr><td><tt>%H</tt></td><td>Hour in 24h format (<tt>00-23</tt>)</td><td><tt>14</tt></td></tr>
    <tr><td><tt>%I</tt></td><td>Hour in 12h format (<tt>01-12</tt>)</td><td><tt>02</tt></td></tr>
    <tr><td><tt>%j</tt></td><td>Day of the year (<tt>001-366</tt>)</td><td><tt>235</tt></td></tr>
    <tr><td><tt>%m</tt></td><td>Month as a decimal number (<tt>01-12</tt>)</td><td><tt>08</tt></td></tr>
    <tr><td><tt>%M</tt></td><td>Minute (<tt>00-59</tt>)</td><td><tt>55</tt></td></tr>
    <tr><td><tt>%p</tt></td><td>AM or PM designation</td><td><tt>PM</tt></td></tr>
    <tr><td><tt>%S</tt></td><td>Second (<tt>00-61</tt>)</td><td><tt>02</tt></td></tr>
    <tr><td><tt>%U</tt></td><td>Week number with the first Sunday as the first day of week one (<tt>00-53</tt>)</td><td><tt>33</tt></td></tr>
    <tr><td><tt>%w</tt></td><td>Weekday as a decimal number with Sunday as <tt>0</tt> (<tt>0-6</tt>)</td><td><tt>4</tt></td></tr>
    <tr><td><tt>%W</tt></td><td>Week number with the first Monday as the first day of week one (<tt>00-53</tt>)</td><td><tt>34</tt></td></tr>
    <tr><td><tt>%x</tt></td><td>Date representation *</td><td><tt>08/23/01</tt></td></tr>
    <tr><td><tt>%X</tt></td><td>Time representation *</td><td><tt>14:55:02</tt></td></tr>
    <tr><td><tt>%y</tt></td><td>Year, last two digits (<tt>00-99</tt>)</td><td><tt>01</tt></td></tr>
    <tr><td><tt>%Y</tt></td><td>Year</td><td><tt>2001</tt></td></tr>
    <tr><td><tt>%Z</tt></td><td>Timezone name or abbreviation</td><td><tt>CDT</tt></td></tr>
    <tr><td><tt>%%</tt></td><td>A <tt>%</tt> sign</td><td><tt>%</tt></td></tr>
  </tbody>
</table>


##Printf

<table>
	<tbody>
		<tr> <th>Specifier</th> <th>Output</th> <th>Example</th> </tr>
		<tr> <td><tt>c</tt></td> <td>Character</td><td> <tt>a</tt></td> </tr>
		<tr><td><tt>d</tt> or <tt>i</tt></td><td>Signed decimal integer</td><td><tt>392</tt></td></tr>
		<tr><td><tt>e</tt></td><td>Scientific notation (mantissa/exponent) using <tt>e</tt> character</td><td><tt>3.9265e+2</tt></td></tr>
		<tr><td><tt>E</tt></td><td>Scientific notation (mantissa/exponent) using <tt>E</tt> character</td><td><tt>3.9265E+2</tt></td></tr>
		<tr><td><tt>f</tt></td><td>Decimal floating point</td><td><tt>392.65</tt></td></tr>
		<tr><td><tt>g</tt></td><td>Use the shorter of <tt>%e</tt> or <tt>%f</tt></td><td><tt>392.65</tt></td></tr>
		<tr><td><tt>G</tt></td><td>Use the shorter of <tt>%E</tt> or <tt>%f</tt></td><td><tt>392.65</tt></td></tr>
		<tr><td><tt>o</tt></td><td>Unsigned octal</td><td><tt>610</tt></td></tr>
		<tr><td><tt>s</tt></td><td>String of characters</td><td><tt>sample</tt></td></tr>
		<tr><td><tt>u</tt></td><td>Unsigned decimal integer</td><td><tt>7235</tt></td></tr>
		<tr><td><tt>x</tt></td><td>Unsigned hexadecimal integer</td><td><tt>7fa</tt></td></tr>
		<tr><td><tt>X</tt></td><td>Unsigned hexadecimal integer (capital letters)</td><td><tt>7FA</tt></td></tr>
		<tr><td><tt>p</tt></td><td>Pointer address</td><td><tt>B800:0000</tt></td></tr>
		<tr><td><tt>n</tt></td><td>Nothing printed. The argument must be a pointer to a signed <tt>int</tt>, where the number of characters written so far is stored.</td><td>  </td></tr>
		<tr><td><tt>%</tt></td><td>A <tt>%</tt> followed by another <tt>%</tt> character will write <tt>%</tt> to <tt>stdout</tt>.</td><td><tt>%</tt></td></tr>
	</tbody>
</table>


##Pack

<table class="doctable table">
  <thead>
    <tr>
      <th>Code</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody >
    <tr>
      <td>a</td>
      <td>NUL-padded string</td>
    </tr>
    <tr>
      <td>A</td>
      <td>SPACE-padded string</td></tr>
    <tr>
      <td>h</td>
      <td>Hex string, low nibble first</td>
    </tr>
    <tr>
      <td>H</td>
      <td>Hex string, high nibble first</td>
    </tr>
    <tr><td>c</td><td>signed char</td></tr>
    <tr>
      <td>C</td>
      <td>unsigned char</td>
    </tr>
    <tr>
      <td>s</td>
      <td>signed short (always 16 bit, machine byte order)</td>
    </tr>
    <tr>
      <td>S</td>
      <td>unsigned short (always 16 bit, machine byte order)</td>
    </tr>
    <tr>
      <td>n</td>
      <td>unsigned short (always 16 bit, big endian byte order)</td>
    </tr>
    <tr>
      <td>v</td>
      <td>unsigned short (always 16 bit, little endian byte order)</td>
    </tr>
    <tr>
      <td>i</td>
      <td>signed integer (machine dependent size and byte order)</td>
    </tr>
    <tr>
      <td>I</td>
      <td>unsigned integer (machine dependent size and byte order)</td>
    </tr>
    <tr>
      <td>l</td>
      <td>signed long (always 32 bit, machine byte order)</td>
    </tr>
    <tr>
      <td>L</td>
      <td>unsigned long (always 32 bit, machine byte order)</td>
    </tr>
    <tr>
      <td>N</td>
      <td>unsigned long (always 32 bit, big endian byte order)</td>
    </tr>
    <tr>
      <td>V</td>
      <td>unsigned long (always 32 bit, little endian byte order)</td>
    </tr>
    <tr>
      <td>f</td>
      <td>float (machine dependent size and representation)</td>
    </tr>
    <tr>
      <td>d</td>
      <td>double (machine dependent size and representation)</td>
    </tr>
    <tr>
      <td>x</td>
      <td>NUL byte</td>
    </tr>
    <tr>
      <td>X</td>
      <td>Back up one byte</td>
    </tr>
    <tr>
      <td>@</td>
      <td>NUL-fill to absolute position</td>
    </tr>
  </tbody>
</table>


##Avro Types

<table>
  <thead>
  <tr>
    <th>Name</th>
    <th>Description</th>
   </tr>
  </thead>
  <tbody>
  <tr>
    <td>string</td><td> unicode character sequence</td></tr>
  <tr>
    <td>bytes</td><td> sequence of 8-bit bytes</td></tr>
  <tr>
    <td>int</td><td> 32-bit signed integer</td></tr>
  <tr>
    <td>long</td><td> 64-bit signed integer</td></tr>
  <tr>
    <td>float</td><td> single precision (32-bit) IEEE 754 floating-point number</td></tr>
  <tr>
    <td>double</td><td> double precision (64-bit) IEEE 754 floating-point number</td></tr>
  <tr>
    <td>boolean</td><td> a binary value</td></tr>
  <tr>
    <td>null</td><td> no value</td>
  </tr>
  </tbody>
</table>
