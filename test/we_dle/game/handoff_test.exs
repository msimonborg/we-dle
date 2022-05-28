defmodule WeDle.Game.HandoffTest do
  use ExUnit.Case, async: false

  import WeDle.Game

  alias Ecto.Adapters.SQL.Sandbox
  alias WeDle.{Game, Game.Board, Game.Player, Handoffs, Repo}

  setup do
    # Our Postgres notification doesn't trigger inside of a sandbox,
    # i.e. without a committed insert, so we must set `:sandbox` to
    # `false`. Also, our notification is triggered with an insertion
    # by another process (the `WeDle.Game.Server`), so we must share
    # the connection with other processes by setting `shared: true`.
    pid = Sandbox.start_owner!(Repo, shared: true, sandbox: false)

    on_exit(fn ->
      # Since we're outside of the sandbox there will be no rollback
      # after the test, so we must manually delete all handoffs.
      Handoffs.delete_all_handoffs()
      Sandbox.stop_owner(pid)
    end)

    :ok
  end

  describe "game state handoff" do
    test "a game can handoff its state at shutdown to a new instance" do
      game = "handoff1"

      {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
      {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")

      {:ok, %Player{challenge: "hello"}} = set_challenge(game, "p1", "hello")
      {:ok, %Player{challenge: "world"}} = set_challenge(game, "p2", "world")

      game_pid = whereis(game)
      assert is_pid(game_pid)

      Process.exit(game_pid, :shutdown)

      Process.sleep(10)

      assert whereis(game) |> is_nil()

      # The state is restored
      assert {:ok, %Player{challenge: "hello"}} = start_or_join(game, "p1")
      assert {:ok, %Player{challenge: "world"}} = start_or_join(game, "p2")

      assert whereis(game) |> is_pid()

      # The handoff has been deleted after it was used
      assert Handoffs.get_handoff(game) |> is_nil()
    end

    test "a game will receive a newly synced state handoff after the game has started" do
      game = "handoff2"

      {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
      {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")

      handoff_state = %Game{
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
        started_at: DateTime.utc_now()
      }

      Handoffs.create_handoff(handoff_state)

      # Wait for handoff to be delivered
      Process.sleep(50)

      # The game has updated it's state from the handoff
      assert {:ok, %Player{challenge: "hello"}} = start_or_join(game, "p1")
      assert {:ok, %Player{challenge: "world"}} = start_or_join(game, "p2")

      # The handoff has been deleted after it was used
      assert Handoffs.get_handoff(game) |> is_nil()
    end

    test "game does not handoff state when exit reason is normal" do
      game = "handoff3"

      {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
      {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")

      {:ok, %Player{challenge: "hello"}} = set_challenge(game, "p1", "hello")
      {:ok, %Player{challenge: "world"}} = set_challenge(game, "p2", "world")

      game_pid = whereis(game)
      assert is_pid(game_pid)

      Process.exit(game_pid, :normal)

      Process.sleep(10)

      assert whereis(game) |> is_nil()

      # The game is started over again and the handoff state was not saved
      assert {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
      assert {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")
    end
  end
end
