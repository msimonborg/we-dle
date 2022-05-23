# defmodule WeDle.Game.HandoffTest do
#   use ExUnit.Case

#   import WeDle.Game

#   alias Ecto.Adapters.SQL.Sandbox
#   alias WeDle.{Game, Game.Board, Game.Player, Handoffs, Repo}

#   setup_all do
#     on_exit(fn ->
#       WeDle.Handoffs.delete_all_handoffs()
#     end)
#   end

#   describe "game state handoff" do
#     test "a game can handoff its state at shutdown to a new instance" do
#       Sandbox.unboxed_run(Repo, fn ->
#         game = "handoff1"

#         {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
#         {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")

#         {:ok, %Player{challenge: "hello"}} = set_challenge(game, "p1", "hello")
#         {:ok, %Player{challenge: "world"}} = set_challenge(game, "p2", "world")

#         game_pid = whereis(game)
#         assert is_pid(game_pid)

#         Process.exit(game_pid, :shutdown)

#         Process.sleep(10)

#         assert whereis(game) |> is_nil()

#         assert {:ok, %Player{challenge: "hello"}} = start_or_join(game, "p1")
#         assert {:ok, %Player{challenge: "world"}} = start_or_join(game, "p2")

#         assert whereis(game) |> is_pid()
#         assert Handoffs.get_handoff(game) |> is_nil()
#       end)
#     end

#     test "a game will receive a newly synced state handoff after the game has started" do
#       Sandbox.unboxed_run(Repo, fn ->
#         game = "handoff2"

#         {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
#         {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")

#         handoff_state = %Game{
#           edge_servers: %{},
#           id: game,
#           players: %{
#             "p1" => %Player{
#               board: %Board{
#                 rows: [[], [], [], [], [], []],
#                 solved: false,
#                 turns: 0,
#                 word_length: 5
#               },
#               challenge: "hello",
#               game_id: game,
#               id: "p1"
#             },
#             "p2" => %Player{
#               board: %Board{
#                 rows: [[], [], [], [], [], []],
#                 solved: false,
#                 turns: 0,
#                 word_length: 5
#               },
#               challenge: "world",
#               game_id: game,
#               id: "p2"
#             }
#           },
#           winner: nil,
#           word_length: 5
#         }

#         Handoffs.create_handoff(handoff_state)

#         Process.sleep(1000)

#         assert {:ok, %Player{challenge: "hello"}} = start_or_join(game, "p1")
#         assert {:ok, %Player{challenge: "world"}} = start_or_join(game, "p2")
#       end)
#     end

#     test "game does not handoff state when exit reason is normal" do
#       Sandbox.unboxed_run(Repo, fn ->
#         game = "handoff3"

#         {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
#         {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")

#         {:ok, %Player{challenge: "hello"}} = set_challenge(game, "p1", "hello")
#         {:ok, %Player{challenge: "world"}} = set_challenge(game, "p2", "world")

#         game_pid = whereis(game)
#         assert is_pid(game_pid)

#         Process.exit(game_pid, :normal)

#         Process.sleep(10)

#         assert whereis(game) |> is_nil()

#         assert {:ok, %Player{challenge: nil}} = start_or_join(game, "p1")
#         assert {:ok, %Player{challenge: nil}} = start_or_join(game, "p2")
#       end)
#     end
#   end
# end
