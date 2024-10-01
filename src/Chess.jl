module Chess

using JuMP
using HiGHS
using PrettyTables

export get_optimal_queen_positions

function get_optimal_queen_positions(N::Int)

    # Create an empty optimization model.
    model = Model(HiGHS.Optimizer)

    # Define the necessary index sets.
    Ω = 1:N
    Ω¹(i, j) = [k for k in -N:N if i + k ∈ Ω && j + k ∈ Ω]
    Ω²(i, j) = [k for k in -N:N if i + k ∈ Ω && j - k ∈ Ω]

    # x[i, j] = 1 if position (i, j) is covered by any of the queens, and 0 otherwise.
    @variable(model, x[Ω, Ω], Bin)

    # y[i, j] = 1 if a queen is placed at position (i, j), and 0 otherwise.
    @variable(model, y[Ω, Ω], Bin)

    # Require that exactly N queens are placed.
    @constraint(model, sum(y[i, j] for i in Ω, j in Ω) == N)

    # Require that the queens cover all positions in their respective rows.
    @constraint(model, [i in Ω, j in Ω], y[i, j] ≤ 1 / N * sum(x[i, k] for k in Ω))

    # Require that the queens cover all positions in their respective columns.
    @constraint(model, [i in Ω, j in Ω], y[i, j] ≤ 1 / N * sum(x[k, j] for k in Ω))

    # Require that the queens cover all positions in their respective main diagonals.
    @constraint(model, [i in Ω, j in Ω], y[i, j] ≤ 1 / length(Ω¹(i, j)) * sum(x[i + k, j + k] for k in Ω¹(i, j)))

    # Require that the queens cover all positions in their respective antidiagonals.
    @constraint(model, [i in Ω, j in Ω], y[i, j] ≤ 1 / length(Ω²(i, j)) * sum(x[i + k, j - k] for k in Ω²(i, j)))

    # Minimize the number of positions covered by the queens.
    @objective(model, Min, sum(x))

    # Solve the optimization problem (without log output).
    set_silent(model)
    optimize!(model)

    # Extract the solution.
    x = round.(Int, value.(x))
    y = round.(Int, value.(y))

    # Print the number of positions not covered by the queens.
    println("Number of positions not covered by the queens: ", round(Int, N^2 - objective_value(model)))

    # Display the position of each queen in a table.
    queen_positions = [y[i, j] ≈ 1 ? "x" : "" for i in Ω, j in Ω]

    # Mark all positions not covered by the queens in blue.
    h1 = Highlighter(
        (data, i, j) -> (x[i, j] ≈ 0),
        background = :blue
    )

    # Mark all positions covered by the queens in red.
    h2 = Highlighter(
        (data, i, j) -> (x[i, j] ≈ 1),
        background = :red
    )

    # Show the table.
    pretty_table(
        queen_positions,
        hlines = 0:N,
        vlines = 0:N,
        show_row_number = false,
        show_header     = false,
        highlighters    = (h1, h2)
    )

    return y
end

end