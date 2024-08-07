module settings

export Settings, exposed_settings, exposed_setters, exposed_options

mutable struct Settings
    wordconstraints::Function
    timelimit::Int
    words_per_line::Int
end

function Settings()
    return Settings(
        x->true,
        0,
        5
    )
end

function set_minmax_constraint(settings::Settings, low_high::Tuple)
    low, high = low_high
    settings.wordconstraints = x-> low ≤ length(x) ≤ high
end

function set_wpl(settings::Settings, value::Int)
    settings.words_per_line = value
end

exposed_settings = ["words per line", "word length"]

exposed_setters =Dict(
    "words per line" => set_wpl,
    "word length" => set_minmax_constraint,
)
exposed_options = Dict(
    "words per line" => [1,3,5,10],
    "word length" => [(1,5), (1,10), (1,20), (5,10), (5,20), (10,20)],
)


end;