defmodule WeDle.Game.HandoffTest do
  use ExUnit.Case

  import WeDle.Game

  alias WeDle.Game
  alias WeDle.Game.{Handoff, Player}

  describe "game state handoff" do
    test "a game can handoff its state at shutdown to a new instance" do
      game = "handoff1"

      {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
      {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")

      {:ok, %Player{challenge: "hello"}} = set_challenge(game, "p1", "hello")
      {:ok, %Player{challenge: "world"}} = set_challenge(game, "p2", "world")

      game_pid = whereis(game)
      assert is_pid(game_pid)

      # The handoff should be empty
      assert Handoff.to_map() == Map.new()

      # Shutdown the process and allow the handoff time to sync
      Process.exit(game_pid, :shutdown)
      send(Handoff, :sync)
      Process.sleep(10)

      assert whereis(game) |> is_nil()

      # Assert that the game state is stored in the handoff
      assert %{^game => %Game{}} = Handoff.to_map()

      # Assert that the handoff is retrieved by the newly started game instance
      assert {:ok, %Player{challenge: "hello"}} = start_or_join(game, "p1")
      assert {:ok, %Player{challenge: "world"}} = start_or_join(game, "p2")

      # The new game instance deletes its state from the handoff, force it
      # to sync and propogate the changes
      send(Handoff, :sync)

      # The game is alive and the handoff is empty again
      assert whereis(game) |> is_pid()
      assert Handoff.to_map() == Map.new()
    end

    test "a game will receive a newly synced state handoff after the game has started" do
      game = "handoff2"

      {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
      {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")

      assert Handoff.to_map() == Map.new()

      handoff_state = %WeDle.Game{
        edge_servers: %{},
        id: game,
        players: %{
          "p1" => %WeDle.Game.Player{
            board: %WeDle.Game.Board{
              rows: [[], [], [], [], [], []],
              solved: false,
              turns: 0,
              word_length: 5
            },
            challenge: "hello",
            game_id: game,
            id: "p1"
          },
          "p2" => %WeDle.Game.Player{
            board: %WeDle.Game.Board{
              rows: [[], [], [], [], [], []],
              solved: false,
              turns: 0,
              word_length: 5
            },
            challenge: "world",
            game_id: game,
            id: "p2"
          }
        },
        winner: nil,
        word_length: 5
      }

      Handoff.put(game, handoff_state)
      send(Handoff, :sync)

      Process.sleep(10)

      assert {:ok, %Player{challenge: "hello"}} = start_or_join(game, "p1")
      assert {:ok, %Player{challenge: "world"}} = start_or_join(game, "p2")
    end

    test "game does not handoff state when exit reason is normal" do
      game = "handoff3"

      {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
      {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")

      # Set state in the game
      {:ok, %Player{challenge: "hello"}} = set_challenge(game, "p1", "hello")
      {:ok, %Player{challenge: "world"}} = set_challenge(game, "p2", "world")

      game_pid = whereis(game)
      assert is_pid(game_pid)

      # The handoff should be empty
      assert Handoff.to_map() == Map.new()

      # Shutdown the process with a reason of :normal and allow the handoff time to sync
      Process.exit(game_pid, :normal)
      send(Handoff, :sync)
      Process.sleep(10)

      assert whereis(game) |> is_nil()

      # Assert that the game state is not stored in the handoff
      assert Handoff.to_map() == Map.new()

      # Assert that the handoff is not retrieved by the newly started game instance
      assert {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
      assert {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")
    end
  end
end
