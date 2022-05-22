defmodule WeDle.Handoffs do
  @moduledoc """
  Context module to work with `WeDle.Schemas.Handoff` structs and
  database operations.
  """

  alias WeDle.{Game, Repo, Schemas.Handoff}

  def create_handoff(%Game{} = game) do
    game
    |> Handoff.changeset_from_game()
    |> Repo.insert()
  end

  def get_handoff(game_id) do
    Repo.get_by(Handoff, game_id: game_id)
  end

  def delete_handoff(%Handoff{} = handoff) do
    Repo.delete(handoff)
  end
end
