using DelimitedFiles

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

function main()
    board = load_board("puzzle.csv", '\t')
    sudoku = Sudoku(board)


    @assert !check_valid(sudoku.board, Placement(Int8(1), Int8(2), Int8(6)))
    @assert !check_valid(sudoku.board, Placement(Int8(1), Int8(2), Int8(5)))
    @assert !check_valid(sudoku.board, Placement(Int8(9), Int8(8), Int8(8)))
    @assert check_valid(sudoku.board, Placement(Int8(9), Int8(8), Int8(6)))

    @assert make_placement!(sudoku, Int8(1), Int8(2), Int8(1))
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end