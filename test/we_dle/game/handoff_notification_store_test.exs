defmodule WeDle.Game.Handoff.NotificationStoreTest do
  use ExUnit.Case, async: false
  import WeDle.Game.Handoff.NotificationStore

  @tab WeDle.Game.Handoff.NotificationStore

  setup do
    prune_table()
    %{id: WeDle.Game.unique_id()}
  end

  test "insert/1 inserts the given game id into the table", %{id: id} do
    assert :ok = insert(id)
    assert [{^id, %DateTime{}}] = :ets.lookup(@tab, id)
  end

  test "contains?/1 checks if the given game id is in the table", %{id: id} do
    refute contains?(id)

    insert(id)
    assert contains?(id)
  end

  test "delete/1 deletes the given game id from the table", %{id: id} do
    insert(id)
    assert contains?(id)

    delete(id)
    refute contains?(id)
  end

  test "prune_table/1 deletes all records from the table older than the interval" do
    ids = Enum.map(1..10_000, &to_string/1)

    for id <- ids do
      insert(id)
      assert contains?(id)
    end

    Process.sleep(5)

    prune_table(1, :millisecond)

    for id <- ids, do: refute(contains?(id))
  end

  test "prune_table/1 does not delete records that are not older than the interval" do
    ids = Enum.map(1..10_000, &to_string/1)

    for id <- ids do
      insert(id)
      assert contains?(id)
    end

    Process.sleep(5)

    prune_table(1, :second)

    for id <- ids, do: assert(contains?(id))
  end
end
