module settings

export Settings, endless_limit_wordlen

struct Settings
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

function endless_limit_wordlen(low, high; wpl=5)
    return Settings(
        x-> low ≤ length(x) ≤ high,
        0,
        wpl
    )
end

end;