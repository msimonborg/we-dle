defmodule WeDle.Game.HandoffTest do
  use WeDle.DataCase, async: false

  import WeDle.Game

  alias WeDle.{Game, Game.Board, Game.Handoff, Game.Player, Handoffs}

  describe "game state handoff" do
    test "a game can handoff its state at shutdown to a new instance" do
      game = unique_id()

      {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
      {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")

      {:ok, %Player{challenge: "hello"}} = set_challenge(game, "p1", "hello")
      {:ok, %Player{challenge: "world"}} = set_challenge(game, "p2", "world")

      game_pid = whereis(game)
      assert is_pid(game_pid)

      Process.exit(game_pid, :shutdown)

      Process.sleep(50)

      assert whereis(game) |> is_nil()

      # The state is restored
      assert {:ok, %Player{challenge: "hello"}} = start_or_join(game, "p1")
      assert {:ok, %Player{challenge: "world"}} = start_or_join(game, "p2")

      assert whereis(game) |> is_pid()

      # The handoff has been deleted after it was used
      assert Handoffs.get_handoff(game) |> is_nil()
    end

    test "a game will receive a newly synced state handoff after the game has started" do
      game = unique_id()

      {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
      {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")

      handoff_state = build_state(id: game)

      Handoffs.create_handoff(handoff_state)

      # Wait for handoff to be delivered
      Process.sleep(50)

      # The game has updated it's state from the handoff
      assert {:ok, %Player{challenge: "hello"}} = start_or_join(game, "p1")
      assert {:ok, %Player{challenge: "world"}} = start_or_join(game, "p2")

      # The handoff has been deleted after it was used
      assert Handoffs.get_handoff(game) |> is_nil()
    end

    test "a game will not receive a handoff if the state is too old" do
      game = unique_id()

      {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
      {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")

      expiration_time = Handoff.expiration_time(:second)
      old_time = DateTime.add(DateTime.utc_now(), -(expiration_time + 1), :second)

      handoff_state = build_state(id: game, started_at: old_time)

      assert {:error, _} = Handoffs.create_handoff(handoff_state)
      assert Handoffs.get_handoff(game) |> is_nil()

      # Wait for handoff to be delivered
      Process.sleep(50)

      # The game has not updated its state
      assert {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
      assert {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")
    end

    defp build_state(opts) do
      game = Keyword.fetch!(opts, :id)
      started_at = Keyword.get(opts, :started_at, DateTime.utc_now())

      %Game{
        edge_servers: %{},
        id: game,
        players: %{
          "p1" => %Player{
            board: %Board{
              rows: [[], [], [], [], [], []],
              solved: false,
              turns: 0,
              word_length: 5
            },
            challenge: "hello",
            game_id: game,
            id: "p1"
          },
          "p2" => %Player{
            board: %Board{
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
        word_length: 5,
        started_at: started_at
      }
    end
  end
end
