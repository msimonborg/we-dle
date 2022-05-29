defmodule WeDle.GameTest do
  use WeDle.DataCase
  @moduletag :capture_log
  doctest WeDle.Game

  # Wait for doctests to finish to avoid DBConnection errors.
  # Each game server stores its state in the `terminate` callback
  # upon receiving a :shutdown signal. The test may exit before
  # the `terminate` callback finishes executing, causing a DB
  # connection error.
  Process.sleep(100)

  import WeDle.Game

  describe "join/2" do
    test "a message is sent to the client when the game disconnects or is stopped" do
      game = "join"
      {:ok, pid} = start(game)
      {:ok, _player} = join(game, "p1")
      true = Process.exit(pid, :shutdown)

      msg =
        receive do
          msg -> msg
        end

      assert {:game_down, :shutdown} = msg
    end
  end

  describe "exists?/1" do
    test "checks if a game exists either as a running server or an available handoff" do
      game = "exists"

      refute exists?(game)

      {:ok, _} = start_or_join(game, "p1")
      assert exists?(game)

      pid = whereis(game)

      Process.exit(pid, :shutdown)
      Process.sleep(10)

      assert game |> whereis() |> is_nil()
      assert exists?(game)
      refute WeDle.Handoffs.get_handoff(game) |> is_nil()
    end
  end
end
