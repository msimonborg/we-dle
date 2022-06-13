defmodule WeDle.Game.EdgeServerTest do
  use WeDle.DataCase
  import WeDle.Game.EdgeServer
  alias WeDle.Game

  describe "edge_server" do
    test "can be started for multiple clients" do
      game_id = Game.unique_id()
      {:ok, _} = Game.start(game_id)
      parent = self()

      client_fun = fn ->
        Game.join(game_id, "p1")

        receive do
          msg -> send(parent, from: self(), message: msg)
        end
      end

      client1 = spawn(client_fun)
      client2 = spawn(client_fun)

      Process.sleep(10)

      Game.force_expire(game_id)

      assert_receive from: ^client1, message: {:game_down, {:shutdown, :expired}}
      assert_receive from: ^client2, message: {:game_down, {:shutdown, :expired}}
    end

    test "shuts down when there are no more connected clients" do
      game_id = Game.unique_id()
      {:ok, _} = Game.start(game_id)

      client_fun = fn ->
        Game.join(game_id, "p1")
        Process.sleep(:infinity)
      end

      client1 = spawn(client_fun)
      Process.sleep(5)
      assert pid = whereis(game_id, "p1")
      assert Process.alive?(pid)

      client2 = spawn(client_fun)
      Process.sleep(5)
      assert ^pid = whereis(game_id, "p1")
      assert Process.alive?(pid)

      Process.exit(client1, :kill)
      Process.sleep(5)
      assert ^pid = whereis(game_id, "p1")
      assert Process.alive?(pid)

      Process.exit(client2, :kill)
      Process.sleep(5)
      assert whereis(game_id, "p1") == nil
      refute Process.alive?(pid)
    end
  end
end
