defmodule Exjs.Optimizer do
  @moduledoc """
  Exjs optimizer.
  """

  @doc """
  Optimize the AST of Elixir .

  ## Examples

    iex> Exjs.Optimizer.optimize {:fn, [], [[{:x, [], nil}], {:return, [], {:+, [], [{:+, [], [2, 2]}, {:x, [], nil}]}}]}
    {:fn, [], [[{:x, [], nil}], {:return, [], {:+, [], [4, {:x, [], nil}]}}]}

    iex> Exjs.Optimizer.optimize {:fn, [], [[{:x, [], nil}], {:return, [], {:*, [], [{:*, [], [2, 2]}, {:x, [], nil}]}}]}
    {:fn, [], [[{:x, [], nil}], {:return, [], {:*, [], [4, {:x, [], nil}]}}]}

    iex> Exjs.Optimizer.optimize {:+, [], [1, :x]}
    {:+, [], [1, :x]}

    iex> Exjs.Optimizer.optimize {:*, [], [1, :x]}
    {:*, [], [1, :x]}

    iex> Exjs.Optimizer.optimize {:-, [], [1, :x]}
    {:-, [], [1, :x]}

    iex> Exjs.Optimizer.optimize {:/, [], [1, :x]}
    {:/, [], [1, :x]}

    iex> Exjs.Optimizer.optimize {:+, [], [2, 2]}
    4

    iex> Exjs.Optimizer.optimize {:*, [], [2, 2]}
    4

    iex> Exjs.Optimizer.optimize {:-, [], [4, 2]}
    2

    iex> Exjs.Optimizer.optimize {:/, [], [4, 2]}
    2.0

    iex> Exjs.Optimizer.optimize {0, [], nil}
    0

    iex> Exjs.Optimizer.optimize {:+, [], [{:+, [], [{:+, [], [{:+, [], [{:+, [], [{:+, [], [{:+, [], [1, 2]}, 3]}, 4]}, 5]}, 6]}, 7]}, 8]}
    36

    iex> Exjs.Optimizer.optimize {:*, [], [{:*, [], [{:*, [], [{:*, [], [{:*, [], [{:*, [], [{:*, [], [1, 2]}, 3]}, 4]}, 5]}, 6]}, 7]}, 8]}
    40320

    iex> Exjs.Optimizer.optimize {:x, [], nil}
    {:x, [], nil}

    iex> Exjs.Optimizer.optimize {0, [debug: true], nil}
    {0, [debug: true], nil}

    iex> Exjs.Optimizer.optimize nil
    nil

  """
  # Optimizations
  def optimize({operator, properties, nil}) when is_number(operator) and length(properties) == 0 do
    optimize operator
  end
  def optimize({:+, properties, [operator1, operator2]}) when is_number(operator1) and is_number(operator2) do
    optimize {operator1 + operator2, properties, nil}
  end
  def optimize({:*, properties, [operator1, operator2]}) when is_number(operator1) and is_number(operator2) do
    optimize {operator1 * operator2, properties, nil}
  end
  def optimize({:-, properties, [operator1, operator2]}) when is_number(operator1) and is_number(operator2) do
    optimize {operator1 - operator2, properties, nil}
  end
  def optimize({:/, properties, [operator1, operator2]}) when is_number(operator1) and is_number(operator2) do
    optimize {operator1 / operator2, properties, nil}
  end
  # Optimize multiple operations in the AST
  def optimize({operation, properties, [operator1, operator2]}) when is_tuple(operator1) or is_tuple(operator2) do
    operator1 = optimize operator1
    operator2 = optimize operator2
    if is_tuple(operator1) or is_tuple(operator2) do
      {operation, properties, [operator1, operator2]}
    else
      optimize {operation, properties, [operator1, operator2]}
    end
  end
  # Common node processor
  def optimize({token, properties, content}) do
    token = token
    |> optimize
    content = content
    |> optimize
    {token, properties, content}
  end
  # List of nodes to process
  def optimize(content) when is_list content do
    content
    |> Enum.map(fn(item) -> optimize item end)
  end
  # Simple node or content
  def optimize(content) do
    content
  end
end
