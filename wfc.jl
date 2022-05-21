include("sudoku.jl")

using Random
using Printf
# https://github.com/mxgmn/WaveFunctionCollapse

# Set of "Options", i.e. possible things to put at given grid

# Aka patterns

mutable struct Solution
    wave::Matrix{Array{Bool}}
    n_options::Int
    weights::Matrix{Float64}
    sudoku::Sudoku
end

function Solution(n_options::Int, size::Tuple, sudoku::Sudoku)
    wave::Matrix{Array{Bool}} = fill(fill(true, n_options), size)
    weights = fill(1.0, size)
    Solution(wave, n_options, weights, sudoku)
end


function solution_entropy!(solution::Solution)
    """
    reduces valid options in solution and calculates the entropy, which is returned.
    validation_func is a callable that takes the index of the suggested pattern, as well as an index, 
    and returns 1 if it is invalid and 0 otherwise. It should also return 1 if the selected option is true from the beginning
    """
    entropies = zeros(size(solution.wave))
    for i in CartesianIndices(solution.wave)
        solution.wave[i] = map(x -> validate(solution, x, i), 1:solution.n_options)
        entropies[i] = log(sum(solution.wave[i]))
    end
    entropies
end

function propagate_collapse!(solution::Solution)
    """Collapse all elements in the solution"""
    for i in findall(x->sum(x) == 1, solution.wave)
        update!(solution, findall(x->x, solution.wave[i])[1], i)
    end
end

function solve_wfc!(solution::Solution, random_engine::MersenneTwister=MersenneTwister(0), brute_force::Bool=true)::Tuple{Solution, Bool}
    while true
        # calculate entropies
        entropies = solution_entropy!(solution)
        # find minimum nonzero entropy, i.e. element with lowest possible amount of options
        entropies[entropies.==0] .= Inf # If we have one option locked in, we do not want to select it
        entropies[entropies.==-Inf] .= Inf # If undefined, i.e. no options
        if all(isinf.(entropies))
            # make the final collapse
            propagate_collapse!(solution)
            break
        end
        entropies = entropies.*solution.weights
        _, min_idx = findmin(entropies)
        # set the element to a definite state, i.e. do a collapse
        element = solution.wave[min_idx]
        choice = rand(random_engine, findall(x -> x, element))
        solution.wave[min_idx] .= false 
        solution.wave[min_idx][choice] = true # locked in, i.e. we have made our choice
        update!(solution, choice, min_idx)
        # additionally, we want to update all elements where there is only one valid piece
        propagate_collapse!(solution)
    end
    # check if a valid solution was actually found
    solution, all(sum.(solution.wave) .== 1)
end

function validate(sol::Solution, x::Int, i::CartesianIndex)
    return check_valid(sol.sudoku.board, Placement(i[1], i[2], x))
end

function update!(sol::Solution, x::Int, i::CartesianIndex)
    make_placement!(sol.sudoku, Placement(i[1], i[2], x))
end

function sudoku_example()
    ### Sudoku example
    board = load_board("puzzle.csv", '\t')
    # board::Matrix{Int8} = zeros(9, 9)
    # initialize wave

    iteration = 1
    weights::Matrix{Float64} = fill(1, size(board))
    while true
        
        println(iteration)
        iteration += 1
        board_copy = copy(board)
        sudoku = Sudoku(board_copy)
        solution = Solution(9, (9, 9), sudoku)
        solution.weights = weights
        _, finished = solve_wfc!(solution)

        if finished
            display(solution.sudoku.board)
            break
        else
            # update weights
            weights[sum.(solution.wave) .== 0] ./= 2
            weights ./= sum(sum(weights))
        end
    end
end

sudoku_example()
