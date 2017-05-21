defmodule Exjs.Generator do
  @moduledoc """
  Exjs generator of Javascript code from AST parsed and transformed.
  """

  @doc """
  Generate the Javascript code from the Elixir AST.

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

    iex> Exjs.Generator.generate {:-, [], [1, :x]}
    "1-x"

    iex> Exjs.Generator.generate {:/, [], [1, :x]}
    "1/x"

    iex> Exjs.Generator.generate [1, 2]
    "[1,2]"

    iex> Exjs.Generator.generate {:{}, [], [1, 2, 3]}
    "[1,2,3]"

    iex> Exjs.Generator.generate [1, 2, {:x, [], nil}, 4]
    "[1,2,x,4]"

    iex> Exjs.Generator.generate {:return, [], {:x, [], nil}}
    "return x"

    iex> Exjs.Generator.generate {:return, [], {:+, [], [1, :x]}}
    "return 1+x"

    iex> Exjs.Generator.generate {:return, [], {:*, [], [1, :x]}}
    "return 1*x"

    iex> Exjs.Generator.generate {:=, [], [{:x, [], nil}, 0]}
    "x=0"

    iex> Exjs.Generator.generate {:=, [], [{:x, [], nil}, {:y, [], nil}]}
    "x=y"

    iex> Exjs.Generator.generate {:fn, [], [[{:x, [], nil}], {:return, [], {:+, [], [4, {:x, [], nil}]}}]}
    "function(x){return 4+x}"

    iex> Exjs.Generator.generate {:fn, [], [[{:x, [], nil}], {:return, [], {:*, [], [4, {:x, [], nil}]}}]}
    "function(x){return 4*x}"

    iex> Exjs.Generator.generate {:def, [], [{:x, [], nil}, [{:return, [], 0}]]}
    "this.x=function(){return 0}"

    iex> Exjs.Generator.generate {:def, [], [{:x, [], nil}, [{:=, [], [{:x, [], nil}, 0]}, {:return, [], {:x, [], nil}}]]}
    "this.x=function(){x=0;return x}"

    iex> Exjs.Generator.generate {:defp, [], [{:same, [], [{:x, [], nil}]}, [{:return, [], {:x, [], nil}}]]}
    "function same(x){return x}"

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
  # Private functions
  def generate({:defp, _properties, [{function_name, _function_properties, parameters}, content]}) do
    parameters =
      parameters
      |> generate_sub_nodes
      |> Enum.join(",")

    content =
      content
      |> generate_sub_nodes
      |> Enum.join(";")

    "function #{function_name}(#{parameters}){#{content}}"
  end
  # Public functions
  def generate({:def, _properties, [{function_name, _function_properties, parameters}, content]}) do
    parameters =
      parameters
      |> generate_sub_nodes
      |> Enum.join(",")

    content =
      content
      |> generate_sub_nodes
      |> Enum.join(";")

    "this.#{function_name}=function(#{parameters}){#{content}}"
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
  def generate({:=, _properties, [operator1, operator2]}) do
    operator1 = generate operator1
    operator2 = generate operator2
    "#{operator1}=#{operator2}"
  end
  # Tuple
  def generate({:{}, _properties, content}) do
    generate content
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
  defp generate_sub_nodes(nil) do
    []
  end
  defp generate_sub_nodes(content) when is_list content do
    Enum.map content, fn(item) ->
      generate(item)
    end
  end
end
