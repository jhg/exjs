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

    iex> Exjs.compile_from_string "fn(x) -> 4 + x end"
    "function(x){return 4+x}"

    iex> Exjs.compile_from_string "fn(x) -> 4 * x end"
    "function(x){return 4*x}"

    iex> Exjs.compile_from_string "fn(x) -> 4 - x end"
    "function(x){return 4-x}"

    iex> Exjs.compile_from_string "fn(x) -> 4 / x end"
    "function(x){return 4/x}"

    iex> Exjs.compile_from_string "0"
    "0"

    iex> Exjs.compile_from_string "Window.Console.log []"
    "window.console.log([])"

    iex> Exjs.compile_from_string "List.first [1, 2]"
    "List.first([1,2])"

    iex> Exjs.compile_from_string "List.first x"
    "List.first(x)"

    iex> Exjs.compile_from_string "length x"
    "x.length"

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
