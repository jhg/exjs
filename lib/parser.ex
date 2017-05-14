defmodule Exjs.Parser do
  @moduledoc """
  Exjs parser.
  """

  @doc """
  Parse the code wrote in Elixir.

  ## Examples

    iex> Exjs.Parser.parse "fn(x) -> x * x end"
    {:fn, [], [[{:x, [], nil}], {:return, [], {:*, [], [{:x, [], nil}, {:x, [], nil}]}}]}

    iex> Exjs.Parser.parse "fn(x) -> 2 * 2 * x end"
    {:fn, [], [[{:x, [], nil}], {:return, [], {:*, [], [{:*, [], [2, 2]}, {:x, [], nil}]}}]}

    iex> Exjs.Parser.parse "def x do x end"
    {:def, [], [{:x, [], nil}, [{:do, [], {:x, [], nil}}]]}

    iex> Exjs.Parser.parse "4 + 2"
    {:+, [], [4, 2]}

    iex> Exjs.Parser.parse "4 * 2"
    {:*, [], [4, 2]}

    iex> Exjs.Parser.parse "4 - 2"
    {:-, [], [4, 2]}

    iex> Exjs.Parser.parse "4 / 2"
    {:/, [], [4, 2]}

    iex> Exjs.Parser.parse "Window.Console.log []"
    {{:., [], [{:__aliases__, [], [:Window, :Console]}, :log]}, [], [[]]}

    iex> Exjs.Parser.parse "1 + 2 + 3 + 4 + 5 + 6 + 7 + 8"
    {:+, [], [{:+, [], [{:+, [], [{:+, [], [{:+, [], [{:+, [], [{:+, [], [1, 2]}, 3]}, 4]}, 5]}, 6]}, 7]}, 8]}

    iex> Exjs.Parser.parse "1 * 2 * 3 * 4 * 5 * 6 * 7 * 8"
    {:*, [], [{:*, [], [{:*, [], [{:*, [], [{:*, [], [{:*, [], [{:*, [], [1, 2]}, 3]}, 4]}, 5]}, 6]}, 7]}, 8]}

    iex> Exjs.Parser.parse "()"
    nil

    iex> Exjs.Parser.parse ""
    nil

    iex> Exjs.Parser.parse "[1, 2]"
    [1, 2]

    iex> Exjs.Parser.parse "List.first [1, 2]"
    {{:., [], [{:__aliases__, [counter: 0], [:List]}, :first]}, [], [[1, 2]]}

    iex> Exjs.Parser.parse "length x"
    {:length, [], [{:x, [], nil}]}

  """
  @spec parse(binary) :: tuple | nil | list
  def parse(content) do
    content
    |> Code.string_to_quoted!
    |> process_all_ast
  end

  # Simplifie the fn block
  defp process_all_ast({:fn, properties, [{:->, block_properties, content}]}) do
    [last_sentence|rest_sentences] = Enum.reverse content
    content = Enum.reverse [{:return, [], last_sentence}|rest_sentences]
    process_all_ast {:fn, properties ++ block_properties, content}
  end
  # Simplifie the do block
  defp process_all_ast({:do, properties, {:__block__, block_properties, content}}) do
    process_all_ast {:do, properties ++ block_properties, content}
  end
  # Common node processor
  defp process_all_ast({token, properties, content}) do
    token = token
    |> process_all_ast
    properties = properties
    |> process_all_properties
    content = content
    |> process_all_ast
    {token, properties, content}
  end
  defp process_all_ast({token, content}) do
    process_all_ast {token, [], content}
  end
  # List of nodes to process
  defp process_all_ast(content) when is_list content do
    content
    |> Enum.filter(fn(item) ->
      # Clean the AST
      case item do
        {:doc, _options, _content} -> false
        {:moduledoc, _options, _content} -> false
        {:doctest, _options, _content} -> false
        _ -> true
      end
    end)
    |> Enum.map(fn(item) -> process_all_ast item end)
  end
  # Simple node or content
  defp process_all_ast(content) do
    content
  end

  # Process properties of nodes
  defp process_all_properties(properties) when is_list properties do
    properties
    |> Enum.filter(fn(item) ->
      # Clean the AST
      case item do
        {:line, _number} -> false
        _ -> true
      end
    end)
  end
end
