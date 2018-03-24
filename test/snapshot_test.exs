defmodule SnapshotTest do
  use ExUnit.Case
  doctest Snapshot

  test "greets the world" do
    assert Snapshot.hello() == :world
  end
end
