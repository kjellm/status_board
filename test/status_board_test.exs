defmodule StatusBoardTest do
  use ExUnit.Case
  doctest StatusBoard

  test "greets the world" do
    assert StatusBoard.hello() == :world
  end
end
