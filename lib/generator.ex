defmodule Exjs.Generator do
  @moduledoc """
  Exjs generator of Javascript code from AST parsed and transformed.
  """

  @doc """
  Optimize the AST of Elixir .

  ## Examples

    iex> Exjs.Generator.generate nil
    "null"

    iex> Exjs.Generator.generate {:x, [], nil}
    "x"

    iex> Exjs.Generator.generate {0, [], nil}
    "0"

    iex> Exjs.Generator.generate {0, [debug: true], nil}
    "0"

    iex> Exjs.Generator.generate 2
    "2"

    iex> Exjs.Generator.generate 2.0
    "2.0"

    iex> Exjs.Generator.generate {:+, [], [1, :x]}
    "1+x"

    iex> Exjs.Generator.generate {:*, [], [1, :x]}
    "1*x"

    iex> Exjs.Generator.generate [1, 2]
    "[1,2]"

    iex> Exjs.Generator.generate [1, 2, {:x, [], nil}, 4]
    "[1,2,x,4]"

    iex> Exjs.Generator.generate {:return, [], {:x, [], nil}}
    "return x"

    iex> Exjs.Generator.generate {:return, [], {:+, [], [1, :x]}}
    "return 1+x"

    iex> Exjs.Generator.generate {:return, [], {:*, [], [1, :x]}}
    "return 1*x"

    iex> Exjs.Generator.generate {:fn, [], [[{:x, [], nil}], {:return, [], {:+, [], [4, {:x, [], nil}]}}]}
    "function(x){return 4+x}"

    iex> Exjs.Generator.generate {:fn, [], [[{:x, [], nil}], {:return, [], {:*, [], [4, {:x, [], nil}]}}]}
    "function(x){return 4*x}"

    iex> Exjs.Generator.generate {:length, [], [{:x, [], nil}]}
    "x.length"

    iex> Exjs.Generator.generate {:length, [], [[1, 2]]}
    "[1,2].length"

  ## TODO
  ## Cases that must be detected in previous steps

    iex> Exjs.Generator.generate {:length, [], [[1, 2], [3, 4]]}
    "[1,2].length"

  """
  # Anonymous functions
  def generate({:fn, _properties, [parameters|content]}) do
    parameters =
      parameters
      |> generate_sub_nodes
      |> Enum.join(",")

    content =
      content
      |> generate_sub_nodes
      |> Enum.join(";")

    "function(#{parameters}){#{content}}"
  end
  # Call to functions
  def generate({{:., _call_properties, [{:__aliases__, _aliases_properties, aliases}, function]}, _properties, parameters}) do
    parameters =
      parameters
      |> generate_sub_nodes
      |> Enum.join(",")

    aliases =
      aliases
      |> Enum.map(fn(item) ->
        case item do
          :Window -> "window"
          :Console -> "console"
          item -> "#{item}"
        end
      end)
      |> Enum.join(".")

    "#{aliases}.#{function}(#{parameters})"
  end
  # length
  def generate({:length, _properties, content}) do
    content =
      content
      |> List.first
      |> generate

    "#{content}.length"
  end
  # Return of function
  def generate({:return, _properties, content}) do
    content = generate content
    "return #{content}"
  end
  # Operations
  def generate({:+, _properties, [operator1, operator2]}) do
    operator1 = generate operator1
    operator2 = generate operator2
    "#{operator1}+#{operator2}"
  end
  def generate({:*, _properties, [operator1, operator2]}) do
    operator1 = generate operator1
    operator2 = generate operator2
    "#{operator1}*#{operator2}"
  end
  def generate({:-, _properties, [operator1, operator2]}) do
    operator1 = generate operator1
    operator2 = generate operator2
    "#{operator1}-#{operator2}"
  end
  def generate({:/, _properties, [operator1, operator2]}) do
    operator1 = generate operator1
    operator2 = generate operator2
    "#{operator1}/#{operator2}"
  end
  # Common code generation
  def generate({token, _properties, nil}) do
    token = generate token
    "#{token}"
  end
  # Common node processor
  def generate({token, properties, content}) do
    token = generate token
    content = generate content
    {token, properties, content}
  end
  # Simple node or content
  def generate(content) when is_list content do
    content =
      content
      |> Enum.map(fn(item) -> generate item end)
      |> Enum.join(",")

    "[#{content}]"
  end
  def generate(content) do
    case content do
      nil -> "null"
      _ -> "#{content}"
    end
  end

  # List of nodes to process
  defp generate_sub_nodes(content) when is_list content do
    content
    |> Enum.map(fn(item) -> generate item end)
  end
end
