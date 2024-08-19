module actions
export play, change_settings!, debug

import Term: tprint
import TerminalMenus: RadioMenu, request

include("utils.jl")

using ..scoring: Scorer, register_press!
using ..settings

function change_settings!(settings::Settings)
    # choose setting
    setting_choice = try
        request("Choose Setting to edit: ", RadioMenu(collect(exposed_settings)))
    catch e
        wipelines(1+length(exposed_settings))
        return
    end
    wipelines(1+length(exposed_settings))
    setting_being_changed = exposed_settings[setting_choice]

    # choose value for setting
    value_choice = try
        request("Select value for $setting_being_changed", RadioMenu(string.(exposed_options[setting_being_changed])))
    catch e
        wipelines(1+length(exposed_options[setting_being_changed]))
        return
    end
    wipelines(1+length(exposed_options[setting_being_changed]))
    
    # apply change
    resulting_value = exposed_options[setting_being_changed][value_choice]
    exposed_setters[setting_being_changed](settings, resulting_value)
end

function debug(terminal)
    print("\n")
    while true
        key = readKey(terminal.in_stream)
        wipelines(1)
        println("pressed $key")
        key in INTERRUPT_KEYS && return
    end
end

function get_line(wordlist; len=4)
    line = []
    for _ in 1:len
        push!(line, wordlist[rand(1:length(wordlist))])
    end
    return join(line, " ")
end


function play_line(terminal, lines, scorer)
    # play single line, return status, elapsed, n_chars, n_words
    written_line = ""
    target = lines[2]
    # while length(written_line) ≤ length(target)
    while true
        # tprint("\r"*stylize_line(written_line, target)*ANSI_CLEAR())
        render_lines(lines, written_line)
        key = readKey(terminal.in_stream)
        # interrups: ctrl+c/d, esc
        key in INTERRUPT_KEYS && return -1

        if key in  [Int(ENTER_KEY), Int(' ')]
            # skip enter or space as first press
            written_line == "" && continue
            # advance cleanly
            written_line == target && break
        end
        
        # advance dirty
        key == Int(ENTER_KEY) && break
        backspace(line) = length(line) > 0 ? written_line[1:end-1] : written_line

        # backpace
        if key == Int(BACKSPACE) || (key == Int(CTRL_BACKSPACE) && written_line != "" && written_line[end] == ' ')
            register_press!(scorer)
            written_line = backspace(written_line)
            # ctrl + backspace
        elseif key == Int(CTRL_BACKSPACE)
            register_press!(scorer)
            while length(written_line) > 0 && written_line[end] != ' '
                written_line = backspace(written_line)
            end
        else
            written_line *= Char(key)
            pos_in_target = minimum(length.([written_line, target]))
            register_press!(scorer; typo=Char(key)!=target[pos_in_target])
        end
    end
    render_lines(lines, written_line)

    lines[2] = stylize_line(written_line, target)
    return 1
end



function play(terminal, wordlist, scorer, settings)
    lines = [""]
    for _ in 1:2
        push!(lines, get_line(wordlist, len=settings.words_per_line))
    end
    print("\n\n\n")
    while true
        returncode = play_line(terminal, lines, scorer)
        popfirst!(lines)
        push!(lines, get_line(wordlist))
        returncode < 0 && return
    end
end

end;
