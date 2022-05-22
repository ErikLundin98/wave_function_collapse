using Plots
include("sudoku.jl")
include("wfc.jl")

function plot_board(board)
    plt = plot(xticks = [3, 6], yticks = [3, 6], xlim = (0, 9), ylim = (0,9), aspect_ratio = 1, xaxis=false, yaxis=false)
    plot_board = transpose(board)
    for i in CartesianIndices(plot_board)
        if plot_board[i] != 0
            annotate!([i[1]-0.5], [10-i[2]-0.5], text(plot_board[i]))
        end
    end
    plot!(plt,xformatter=_->"")
    plot!(plt,yformatter=_->"")
    sleep(0.1)
    plt
end

MATRIX_T = Array{Int8,2}
board_history = Vector{MATRIX_T}()
function save_board!(solution::Solution, board_history::Vector{MATRIX_T})
    push!(board_history, copy(solution.environment.board))
end

println("solving wfc")
sudoku_wfc(load_board("resources/sudoku.csv", '\t'), (solution)->save_board!(solution, board_history))

# println("animating wfc")
# animation = @animate for i ∈ 1:size(board_history, 1)
#     plot_board(board_history[i])
# end
# println("saving wfc animation")
# gif(animation, "wfc_solution.gif", fps=90)
