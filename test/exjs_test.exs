defmodule ExjsTest do
  use ExUnit.Case
  doctest Exjs
  doctest Exjs.Parser
  doctest Exjs.Optimizer
  doctest Exjs.Generator

  test "the truth" do
    assert 1 + 1 == 2
  end
end
