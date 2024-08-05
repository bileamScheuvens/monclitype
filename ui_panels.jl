module ui_panels
export welcome_panel, score_panel, goodbye_panel

import Term: tprint, Panels

include("utils.jl")

using ..scoring: Scorer
using ..scoring: get_cpm, get_elapsed, get_accuracy

function welcome_panel()
    return tprint(Panels.Panel(
        "Minimalistic typing practice - within in your terminal.\n
Press $(colorize("Enter", "key")) to begin, $(colorize("Esc", "key")) to quit $(colorize("s", "key")) to change settings.";
        title="Welcome to MonCLItype."
    ))
end

function score_panel(scorer::Scorer)
    print("\n")
    return tprint(Panels.Panel(
        "Typing test complete after $(get_elapsed(scorer)) seconds. 
WPM: $(round(get_cpm(scorer)/5, digits=2))
CPM: $(get_cpm(scorer))
Accuracy: $(get_accuracy(scorer))%"
    ))
end

function goodbye_panel()
    return tprint(Panels.Panel(
        "Thank you for playing!
See you around and keep practicing 🚀"
    ))
end

end;