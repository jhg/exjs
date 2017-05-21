defmodule Exjs.Parser do
  @moduledoc """
  Exjs parser.
  """

  @doc """
  Parse the code wrote in Elixir.

  Convert from string to quoted and transform the Elixir AST to make easy the
  next steps.

  ## Examples

    iex> Exjs.Parser.parse! "fn(x) -> x * x end"
    {:fn, [], [[{:x, [], nil}], {:return, [], {:*, [], [{:x, [], nil}, {:x, [], nil}]}}]}

    iex> Exjs.Parser.parse! "fn(x) -> 2 * 2 * x end"
    {:fn, [], [[{:x, [], nil}], {:return, [], {:*, [], [{:*, [], [2, 2]}, {:x, [], nil}]}}]}

    iex> Exjs.Parser.parse! "def x do\\n  0\\nend"
    {:def, [], [{:x, [], nil}, [{:return, [], 0}]]}

    iex> Exjs.Parser.parse! "def x do\\n  x = 0\\n  x\\nend"
    {:def, [], [{:x, [], nil}, [{:=, [], [{:x, [], nil}, 0]}, {:return, [], {:x, [], nil}}]]}

    iex> Exjs.Parser.parse! "defp same(x), do: x"
    {:defp, [], [{:same, [], [{:x, [], nil}]}, [{:return, [], {:x, [], nil}}]]}

    iex> Exjs.Parser.parse! "4 + 2"
    {:+, [], [4, 2]}

    iex> Exjs.Parser.parse! "4 * 2"
    {:*, [], [4, 2]}

    iex> Exjs.Parser.parse! "4 - 2"
    {:-, [], [4, 2]}

    iex> Exjs.Parser.parse! "4 / 2"
    {:/, [], [4, 2]}

    iex> Exjs.Parser.parse! "Window.Console.log []"
    {{:., [], [{:__aliases__, [], [:Window, :Console]}, :log]}, [], [[]]}

    iex> Exjs.Parser.parse! "1 + 2 + 3 + 4 + 5 + 6 + 7 + 8"
    {:+, [], [{:+, [], [{:+, [], [{:+, [], [{:+, [], [{:+, [], [{:+, [], [1, 2]}, 3]}, 4]}, 5]}, 6]}, 7]}, 8]}

    iex> Exjs.Parser.parse! "1 * 2 * 3 * 4 * 5 * 6 * 7 * 8"
    {:*, [], [{:*, [], [{:*, [], [{:*, [], [{:*, [], [{:*, [], [{:*, [], [1, 2]}, 3]}, 4]}, 5]}, 6]}, 7]}, 8]}

    iex> Exjs.Parser.parse! "(1 + 2) * 3"
    {:*, [], [{:+, [], [1, 2]}, 3]}

    iex> Exjs.Parser.parse! "1 + 2 * 3"
    {:+, [], [1, {:*, [], [2, 3]}]}

    iex> Exjs.Parser.parse! "()"
    nil

    iex> Exjs.Parser.parse! ""
    nil

    iex> Exjs.Parser.parse! "[1, 2]"
    [1, 2]

    iex> Exjs.Parser.parse! "x"
    {:x, [], nil}

    iex> Exjs.Parser.parse! "List.first [1, 2]"
    {{:., [], [{:__aliases__, [counter: 0], [:List]}, :first]}, [], [[1, 2]]}

    iex> Exjs.Parser.parse! "length x"
    {:length, [], [{:x, [], nil}]}

  """
  @spec parse!(binary) :: tuple | nil | list
  def parse!(content) do
    content
    |> Code.string_to_quoted!
    |> process_all_ast
  end

  # Simplifie the functions block and add the return to transform to Javascript AST
  defp process_all_ast({:fn, properties, [{:->, block_properties, content}]}) do
    content = process_all_content(content)
    process_all_ast {:fn, properties ++ block_properties, content}
  end
  defp process_all_ast({:def, properties, [{name, function_properties, parameters}|[do_content]]}) do
    [{:do, block_properties, content}] = process_all_ast do_content
    content = process_all_content(content)
    properties = process_all_properties(properties++block_properties)
    function_properties = process_all_properties(function_properties)
    parameters = process_all_ast parameters
    {:def, properties, [{name, function_properties, parameters}, content]}
  end
  defp process_all_ast({:defp, properties, [{name, function_properties, parameters}|[do_content]]}) do
    [{:do, block_properties, content}] = process_all_ast do_content
    content = process_all_content(content)
    properties = process_all_properties(properties++block_properties)
    function_properties = process_all_properties(function_properties)
    parameters = process_all_ast parameters
    {:defp, properties, [{name, function_properties, parameters}, content]}
  end
  # Simplifie the do block
  defp process_all_ast({:do, content}) do
    process_all_ast {:do, [], content}
  end
  defp process_all_ast({:do, properties, {:__block__, block_properties, content}}) do
    process_all_ast {:do, properties ++ block_properties, content}
  end
  # Common node processor
  defp process_all_ast({token, properties, content}) do
    token = process_all_ast token
    properties = process_all_properties properties
    content = process_all_ast content
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
    Enum.filter properties, fn(item) ->
      # Clean the AST
      case item do
        {:line, _number} -> false
        _ -> true
      end
    end
  end

  # Add the return
  defp process_all_content(content) when is_list(content) do
    [last_sentence|rest_sentences] = Enum.reverse content
    [{:return, [], last_sentence}|rest_sentences]
    |> Enum.reverse
    |> process_all_ast
  end
  defp process_all_content(content) do
    [process_all_ast({:return, [], content})]
  end
end
