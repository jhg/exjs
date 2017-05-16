defmodule Exjs do
  @moduledoc """
  Documentation for Exjs, Elixir to Javascript compiler.
  """
  alias Exjs.Parser
  alias Exjs.Optimizer
  alias Exjs.Generator

  @doc """
  Compile Elixir code to Javascript.

  ## Examples

    iex> Exjs.compile_from_string "x"
    "x"

    iex> Exjs.compile_from_string "0"
    "0"

    iex> Exjs.compile_from_string "2.0"
    "2.0"

    iex> Exjs.compile_from_string "5 / 2"
    "2.5"

    iex> Exjs.compile_from_string "4 / 2"
    "2.0"

    iex> Exjs.compile_from_string "x / 2"
    "x/2"

    iex> Exjs.compile_from_string "1 + 2 + 3 + 4 + 5 + 6 + 7 + 8"
    "36"

    iex> Exjs.compile_from_string "1 * 2 * 3 * 4 * 5 * 6 * 7 * 8"
    "40320"

    iex> Exjs.compile_from_string "(1 + 2) * 3"
    "9"

    iex> Exjs.compile_from_string "1 + 2 * 3"
    "7"

    iex> Exjs.compile_from_string "Window.Console.log []"
    "window.console.log([])"

    iex> Exjs.compile_from_string "List.first [1, 2]"
    "List.first([1,2])"

    iex> Exjs.compile_from_string "List.first x"
    "List.first(x)"

    iex> Exjs.compile_from_string "length x"
    "x.length"

    iex> Exjs.compile_from_string "fn(x) -> 4 + x end"
    "function(x){return 4+x}"

    iex> Exjs.compile_from_string "fn(x) -> 4 * x end"
    "function(x){return 4*x}"

    iex> Exjs.compile_from_string "fn(x) -> 4 - x end"
    "function(x){return 4-x}"

    iex> Exjs.compile_from_string "fn(x) -> 4 / x end"
    "function(x){return 4/x}"

  """
  def compile_from_string(source_code) do
    source_code
    |> Parser.parse
    |> Optimizer.optimize
    |> Generator.generate
  end

  def compile_from_file!(filename) do
    filename
    |> File.read!
    |> compile_from_string
  end
end
