defmodule WeDle.Handoffs do
  @moduledoc """
  Context module to work with `WeDle.Schemas.Handoff` structs and
  database operations.
  """

  import Ecto.Query

  alias WeDle.{Game, Repo, Schemas.Handoff}

  def list_handoffs do
    Repo.all(Handoff)
  end

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

  def delete_handoffs_older_than(duration, unit)
      when is_integer(duration) and duration >= 0 and
             unit in [:second, :millisecond, :microsecond, :nanosecond] do
    now = NaiveDateTime.utc_now()
    cutoff = NaiveDateTime.add(now, -duration, unit)

    query = from h in Handoff, where: h.inserted_at < ^cutoff

    Repo.delete_all(query)
  end

  def delete_all_handoffs do
    Repo.delete_all(Handoff)
  end
end
