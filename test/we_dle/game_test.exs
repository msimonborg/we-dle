defmodule WeDle.GameTest do
  use ExUnit.Case
  @moduletag :capture_log
  doctest WeDle.Game

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
