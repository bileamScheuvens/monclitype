using Term: tprint

# Enum for escaped (multi-byte) keys such as the arrows or the home/end keys
@enum(Key,
    CTRL_C = 3,
    CTRL_D,
    CTRL_BACKSPACE = 8,
    ENTER_KEY = 13,
    ESC_KEY = 27,
    BACKSPACE = 127,
    ARROW_LEFT = 1000,
    ARROW_RIGHT,
    ARROW_UP,
    ARROW_DOWN,
    DEL_KEY,
    HOME_KEY,
    END_KEY,
    PAGE_UP,
    PAGE_DOWN,
)
# Misc constants
COLORS = Dict(
    "latent" => "#959392",
    "right" => "#FFFFFF",
    "wrong" => "#959392 on_#760000",
    "key" => "#91A5FF",
)

ANSI_UP(code=1) = "\033[$(code)A"
ANSI_CLEAR(code=0) = "\x1b[$(code)K"

INTERRUPT_KEYS = Int.([CTRL_C, CTRL_D, ESC_KEY])

# Enable raw mode. Allows us to process keyboard inputs directly.
function enableRawMode(term)
    try
        REPL.Terminals.raw!(term, true)
        print(term.out_stream, "\x1b[?25l")
        return true
    catch err
        warn("Unable to enter raw mode: $err")
    end
    return false
end

# Disable raw mode. Give control back to Julia REPL if interactive session.
function disableRawMode(term)
    print(term.out_stream, "\x1b[?25h")
    try
        REPL.Terminals.raw!(term, false)
        return true
    catch err
        warn("Unable to disable raw mode: $err")
    end
    
    return false
end


# Reads a single byte from stdin
readNextChar(stream::IO=Base.stdin) = Char(read(stream,1)[1])

# Read the next key from stdin. It is also able to read several bytes for
#   escaped keys such as the arrow keys, home/end keys, etc.
# Escaped keys are returned using the `Key` enum.
function readKey(stream::IO=Base.stdin) ::UInt32
    c = readNextChar(stream)

	# Escape characters
	if c == '\x1b'
        stream.buffer.size < 2 && return '\x1b'
        esc_a = readNextChar(stream)

        if esc_a == 'v'  # M-v
            return UInt32(PAGE_UP)
        elseif esc_a == '<'  # M-<
            return UInt32(HOME_KEY)
        elseif esc_a == '>'  # M->
            return UInt32(END_KEY)
        end

        stream.buffer.size < 3 && return '\x1b'
        esc_b = readNextChar(stream)

		if esc_a == '[' || esc_a == 'O'
			if esc_b >= '0' && esc_b <= '9'
				stream.buffer.size < 4 && return '\x1b'
                esc_c = readNextChar(stream)

				if esc_c == '~'
					if esc_b == '1'
                        return UInt32(HOME_KEY)
					elseif esc_b == '4'
                        return UInt32(END_KEY)
					elseif esc_b == '3'
                        return UInt32(DEL_KEY)
					elseif esc_b == '5'
                        return UInt32(PAGE_UP)
					elseif esc_b == '6'
                        return UInt32(PAGE_DOWN)
					elseif esc_b == '7'
                        return UInt32(HOME_KEY)
					elseif esc_b == '8'
                        return UInt32(END_KEY)
                    else
                        return UInt32('\x1b')
                    end
                end

			else
				# Arrow keys
				if esc_b == 'A'
                    return UInt32(ARROW_UP)
				elseif esc_b == 'B'
                    return UInt32(ARROW_DOWN)
				elseif esc_b == 'C'
                    return UInt32(ARROW_RIGHT)
				elseif esc_b == 'D'
                    return UInt32(ARROW_LEFT)
				elseif esc_b == 'H'
                    return UInt32(HOME_KEY)
				elseif esc_b == 'F'
                    return UInt32(END_KEY)
                else
                    return UInt32('\x1b')
                end
			end
		elseif esc_a == 'H'
            return UInt32(HOME_KEY)
        elseif esc_a == 'F'
            return UInt32(END_KEY)
		end

        return UInt32('\x1b')

    elseif c == '\x16'  # C-v
        return UInt32(PAGE_DOWN)
    elseif c == '\x10'  # C-p
        return UInt32(ARROW_UP)
    elseif c == '\x0e'  # C-n
        return UInt32(ARROW_DOWN)
    else
        return UInt32(c)
	end
end


colorize(instr, case) = "{$(COLORS[case])}$instr{/$(COLORS[case])}" 
function stylize_line(line, target)
    len_l, len_t = length.([line, target])
    out = ""
    for (a,b) in zip(line, target)
        out *= colorize(b, a == b ? "right" : "wrong")
    end
    # TODO: rewrite with ordered shenanigans
    if len_l > len_t
        out *= colorize(line[len_t+1:end], "wrong")
    elseif len_l < len_t
        out *= colorize(target[len_l+1:end], "latent")
    end
    return out
end

function rewrite_line(content)
    print("\r")
    print(ANSI_CLEAR(2))
    tprint(content)
end

function wipelines(n)
    print(ANSI_UP(n))
    for _ in 1:n
        print(ANSI_CLEAR(2), "\n")
    end
    print(ANSI_UP(n))
end

function load_wordlist(; filename=joinpath(@__DIR__, "words_alpha.txt"), wordconstraints::Function=x->true)
    wordlist = open(filename, "r") do f
        readlines(f)
    end
    filter!(wordconstraints, wordlist)
end
