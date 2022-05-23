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
end
