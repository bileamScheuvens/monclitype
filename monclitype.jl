#!/usr/bin/env julia

using Pkg
redirect_stderr(()->Pkg.activate(@__DIR__), devnull)

using REPL
using Term: tprint

include("utils.jl")
include("settings.jl")
using .settings
include("scoring.jl")
using .scoring: Scorer
include("ui_panels.jl")
using .ui_panels
include("actions.jl")
using .actions



function main()
    global terminal
    terminal = REPL.Terminals.TTYTerminal(get(ENV, "TERM", Sys.iswindows() ? "" : "dumb"), Base.stdin, Base.stdout, Base.stderr)
    
    settings = Settings()

    welcome_panel()
    enableRawMode(terminal)
    
    scorer = Scorer()
    # core loop
    while true
        key = readKey(terminal.in_stream)
        key in INTERRUPT_KEYS && break
        if key == Int(ENTER_KEY)
            wordlist = load_wordlist(; wordconstraints=settings.wordconstraints)
            play(terminal, wordlist, scorer, settings)
            score_panel(scorer)
            reset!(scorer)
        elseif Char(key) == 's'
            change_settings!(settings)
            enableRawMode(terminal)
        elseif Char(key) == 'd'
            debug(terminal)
        else
            println("invalid action")
        end
    end

    goodbye_panel()
    disableRawMode(terminal)
end

main()