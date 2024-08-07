module scoring
export Scorer
export get_cpm, get_elapsed, get_accuracy
export register_press!

using Dates

mutable struct Scorer
    keypresses::Vector{Float64}
    errors::Vector{Float64}

    function Scorer(keypresses::Vector{Float64} = Float64[], errors::Vector{Float64} = Float64[])
        new(keypresses, errors)
    end
end

get_elapsed(scorer::Scorer) = round(scorer.keypresses[end] - scorer.keypresses[1]; digits=2)

get_cpm(scorer::Scorer) = round(60 * length(scorer.keypresses) / get_elapsed(scorer); digits=2)
    
get_accuracy(scorer::Scorer) = round(100 * (1 - length(scorer.errors) / length(scorer.keypresses)); digits=2)

function reset!(scorer::Scorer)
    scorer.keypresses = Float64[]
    scorer.errors = Float64[]
end

function register_press!(scorer::Scorer; typo::Bool=false)
    push!(typo ? scorer.errors : scorer.keypresses, time())
end

end;