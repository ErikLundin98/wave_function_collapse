using DelimitedFiles
include("wfc.jl")


struct Placement
    row::Int8
    col::Int8
    number::Int8
end

mutable struct Sudoku
    board::Matrix{Int8}
    placements::Array{Placement}
    Sudoku(board::Matrix{Int8}) = new(board, [])
end

function check_valid(board::Matrix{Int8}, p::Placement)::Bool
    if p.row in collect(1:9) && p.col in collect(1:9)
        if p.number == 0 || p.number == board[p.row, p.col]
            return true
        else # can be more efficient
            subboard_row = div(p.row-1, 3)*3 + 1
            subboard_col = div(p.col-1, 3)*3 + 1
            col_valid = !(p.number in board[:, p.col])
            row_valid = !(p.number in board[p.row, :])
            box_valid = !(p.number in board[subboard_row:subboard_row+2, subboard_col:subboard_col+2])
            empty = board[p.row, p.col] == 0
            valid_nr = p.number in collect(0:9)
            return row_valid && col_valid && box_valid && empty && valid_nr
        end
    end
end

function is_valid_board(board::Matrix{Int8})::Bool
    valid = true
    for i in 1:9
        nonzero_in_row = length(board[board[i, :] .> 0])
        nonzero_in_col = length(board[board[:, i] .> 0])
        valid *= length(unique(board[i, :])) == nonzero_in_row && length(unique(board[:, i])) == nonzero_in_col
    end
    for row in range(1, 7, 3)
        for col in range(1, 7, 3)
            nonzero_in_box = length(board[board[row:row+2, col:col+2] .> 0])
            valid *= length(unique(board[row:row+2, col:col+2])) == nonzero_in_box
        end
    end
    return valid
end

function is_finished_safe(board::Matrix{Int8})::Bool
    return is_finished_unsafe(board) && is_valid_board
end

function is_finished_unsafe(board::Matrix{Int8})::Bool
    return all(x -> x>0 && x<10, board)
end

function make_placement!(sudoku::Sudoku, row::Int8, col::Int8, number::Int8)::Bool
    placement = Placement(row, col, number)
    return make_placement!(sudoku, placement)
end

function make_placement!(sudoku::Sudoku, placement::Placement)
    is_valid = check_valid(sudoku.board, placement)
    if is_valid
        if placement.number > 0
            append!(sudoku.placements, [placement])
        end
        sudoku.board[placement.row, placement.col] = placement.number
    end
    return is_valid
end
function clear_placements!(sudoku::Sudoku)
    for placement in sudoku.placements
        sudoku.board[placement.row, placement.col] = 0
    end
end

function load_board(f_name::String, delim::Char)::Matrix{Int8}
    readdlm(f_name, delim, Int8)
end

function tests()
    board = load_board("puzzle.csv", '\t')
    sudoku = Sudoku(board)


    @assert !check_valid(sudoku.board, Placement(Int8(1), Int8(2), Int8(6)))
    @assert !check_valid(sudoku.board, Placement(Int8(1), Int8(2), Int8(5)))
    @assert !check_valid(sudoku.board, Placement(Int8(9), Int8(8), Int8(8)))
    @assert check_valid(sudoku.board, Placement(Int8(9), Int8(8), Int8(6)))

    @assert make_placement!(sudoku, Int8(1), Int8(2), Int8(1))
end

function callback(solution::Solution)
    board::Matrix = solution.environment.board
    display(board)
end

function sudoku_wfc(board::Matrix{Int8}, callback::Function=nothing)::Nothing
    ### Sudoku example
    validator_func(sol::Solution, x::Int, i::CartesianIndex) = check_valid(sol.environment.board, Placement(i[1], i[2], x))
    update_func(sol::Solution, x::Int, i::CartesianIndex) = make_placement!(sol.environment, Placement(i[1], i[2], x))
    iteration = 1
    weights::Matrix{Float64} = fill(1, size(board))
    while true
        print(iteration, ", ")
        iteration += 1
        solution = Solution{Sudoku}(9, (9, 9), Sudoku(copy(board)))
        solution.weights = weights
        _, finished = solve_wfc!(solution, update_func, validator_func, callback)

        if finished
            display(solution.environment.board)
            break
        else
            weights[sum.(solution.wave) .== 0] ./= 2
            weights ./= sum(sum(weights))
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    sudoku_wfc(load_board("resources/sudoku.csv", '\t'))
end