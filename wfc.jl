using Random
# https://github.com/mxgmn/WaveFunctionCollapse
# Set of "Options", i.e. possible things to put at given grid

mutable struct Solution{T}
    """Struct that is used to iterate towards a solution"""
    wave::Matrix{Array{Bool}}
    n_options::Int
    weights::Matrix{Float64}
    environment::T
end


function Solution{T}(n_options::Int, size::Tuple, environment::T) where T
    """
    Constructor for the solution class
    n_options is the amount of options for each tile
    """
    wave::Matrix{Array{Bool}} = fill(fill(true, n_options), size)
    weights = fill(1.0, size)
    Solution{T}(wave, n_options, weights, environment)
end


function solution_entropy!(solution::Solution, validator::Function)
    """
    Reduces valid options in solution and calculates the entropy, which is returned.
    validtor is a callable that takes the index of the suggested pattern, as well as an index, 
    and returns 1 if it is invalid and 0 otherwise. It should also return 1 if the selected option is true from the beginning
    """
    entropies = zeros(size(solution.wave))
    for i in CartesianIndices(solution.wave)
        solution.wave[i] = map(x -> validator(solution, x, i), 1:solution.n_options)
        entropies[i] = log(sum(solution.wave[i]))
    end
    entropies
end

function propagate_collapse!(solution::Solution, updater::Function)
    """Collapse all elements in the solution"""
    for i in findall(x->sum(x) == 1, solution.wave)
        updater(solution, findall(x->x, solution.wave[i])[1], i)
    end
end

function solve_wfc!(solution::Solution, updater::Function, validator::Function, callback::Function=nothing)::Tuple{Solution, Bool}
    """
    The function that is called to perform the wave function collapse algorithm
    Updater is a function with the signature (Solution, option, index) that modifies Solution.environment
    Validator is a function with the signature (Solution, option, index) that checks if option at index is valid (returns 0/1)
    """
    
    while true
        # calculate entropies
        entropies = solution_entropy!(solution, validator)
        # find minimum nonzero entropy, i.e. element with lowest possible amount of options
        entropies[entropies.==0.0] .= Inf # If we have one option locked in, we do not want to select it
        entropies[entropies.==-Inf] .= Inf # If undefined, i.e. no options
        if all(isinf.(entropies))
            # make the final collapse
            propagate_collapse!(solution, updater)
            break
        end
        entropies .*= solution.weights
        _, min_idx = findmin(entropies)
        # set the element to a definite state, i.e. do a collapse
        element = solution.wave[min_idx]
        choice = rand(findall(x -> x, element))
        solution.wave[min_idx] .= false 
        solution.wave[min_idx][choice] = true # locked in, i.e. we have made our choice
        updater(solution, choice, min_idx)
        # additionally, we want to update all elements where there is only one valid piece
        propagate_collapse!(solution, updater)
        if !isnothing(callback)
            callback(solution)
        end
    end
    # check if a valid solution was actually found
    solution, all(sum.(solution.wave) .== 1)
end
