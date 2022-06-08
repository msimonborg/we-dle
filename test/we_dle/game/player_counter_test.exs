defmodule WeDle.Game.PlayerCounterTest do
  use WeDle.DataCase

  import WeDle.Game.PlayerCounter

  alias WeDle.{Game, Game.PlayerCounter}

  setup do
    # Wait for all games started in previous tests to shutdown
    Process.sleep(50)

    aggregate_count()
    Process.sleep(5)

    {:ok, game_id: Game.unique_id()}
  end

  # Induce the player counter to aggregate the count and broadcast any changes
  defp aggregate_count, do: send(PlayerCounter, :aggregate)

  describe "get/0" do
    test "returns the current global player count", %{game_id: game_id} do
      assert get() == 0

      {:ok, _} = Game.start_or_join(game_id, "p1")

      aggregate_count()
      Process.sleep(5)

      assert get() == 1

      {:ok, _} = Game.start_or_join(game_id, "p2")

      aggregate_count()
      Process.sleep(5)

      assert get() == 2

      game_id |> Game.whereis() |> Process.exit(:shutdown)
      Process.sleep(50)

      aggregate_count()
      Process.sleep(5)

      assert get() == 0
    end
  end

  describe "subscribe/0" do
    test "broadcasts a message when the global player count changes", %{game_id: game_id} do
      :ok = subscribe()

      aggregate_count()
      Process.sleep(5)

      assert {:messages, []} = Process.info(self(), :messages)

      {:ok, _} = Game.start_or_join(game_id, "p1")

      aggregate_count()
      Process.sleep(5)

      assert {:messages, [{"player_counter", 1}]} = Process.info(self(), :messages)
    end
  end
end
