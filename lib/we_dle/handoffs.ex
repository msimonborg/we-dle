defmodule WeDle.Handoffs do
  @moduledoc """
  Context module to work with `WeDle.Schemas.Handoff` structs and
  database operations.
  """

  import Ecto.Query

  alias Phoenix.PubSub
  alias WeDle.{Game, Game.Handoff, Repo}

  @pubsub WeDle.PubSub
  @topic "handoffs"

  @type game_id :: String.t()
  @type handoff :: %Handoff{}
  @type game :: Game.t()

  @doc """
  Lists all handoffs in the database.

  ## Examples

      iex> list_handoffs()
      [%Handoff{}, ...]
  """
  @spec list_handoffs :: [handoff]
  def list_handoffs do
    Repo.all(Handoff)
  end

  @doc """
  Creates a handoff from a `WeDle.Game` struct.

  Returns `{:ok, handoff}` on success, or an error changeset otherwise.

  Broadcasts a `{:handoff_created, game_id}` message on the "handoffs"
  pubsub topic on successful creation.

  ## Examples

      iex> create_handoff(good_game)
      {:ok, %WeDle.Game{}}

      iex> create_handoff(bad_game)
      {:error, changeset}
  """
  @spec create_handoff(game) :: {:ok, handoff} | {:error, Ecto.Changeset.t()}
  def create_handoff(%Game{} = game) do
    result =
      game
      |> Handoff.changeset_from_game()
      |> Repo.insert(await: false)

    case result do
      {:ok, _} = ok ->
        broadcast!({:handoff_created, game.id})
        ok

      error ->
        error
    end
  end

  @doc """
  Returns a handoff from the database by `game_id` if it exists.

  Returns nil if no record is found.

  ## Examples

      iex> get_handoff("existing_game")
      %Handoff{}

      iex> get_handoff("nonexisting_game")
      nil
  """
  @spec get_handoff(game_id) :: handoff | nil
  def get_handoff(game_id) do
    Repo.get_by(Handoff, game_id: game_id)
  end

  @doc """
  Deletes the given handoff from the database.

  Returns the handoff struct if successful and raises otherwise.

  ## Examples

      iex> delete_handoff!(handoff)
      %Handoff{}
  """
  @spec delete_handoff!(handoff) :: handoff
  def delete_handoff!(%Handoff{} = handoff) do
    Repo.delete!(handoff, await: false)
  end

  @doc """
  Deletes all handoffs that have been in the database longer than the
  given `duration`, specified by `unit`.

  Returns an integer representing the number of records
  deleted from the database.

  ## Examples

      iex> delete_handoffs_older_than(600, :second)
      50
      iex> delete_handoffs_older_than(20, :second)
      0
  """
  @spec delete_handoffs_older_than(non_neg_integer, System.time_unit()) :: non_neg_integer
  def delete_handoffs_older_than(duration, unit)
      when is_integer(duration) and duration >= 0 and
             unit in [:second, :millisecond, :microsecond, :nanosecond] do
    now = NaiveDateTime.utc_now()
    cutoff = NaiveDateTime.add(now, -duration, unit)

    query = from h in Handoff, where: h.inserted_at < ^cutoff

    with {num, nil} <- Repo.delete_all(query, await: false), do: num
  end

  @doc """
  Deletes all handoffs from the database.

  Returns an integer representing the number of records
  deleted from the database.

  ## Examples

      iex> delete_all_handoffs()
      50
      iex> delete_all_handoffs()
      0
  """
  @spec delete_all_handoffs :: non_neg_integer
  def delete_all_handoffs do
    with {num, nil} <- Repo.delete_all(Handoff, await: false), do: num
  end

  @doc """
  Deletes handoff by `game_id` if it exists.

  Returns `true` if a record existed, otherwise returns false.

  ## Examples

      iex> create_handoff(game)
      iex> delete_handoff_if_exists(game.id)
      true
      iex> delete_handoff_if_exists(game.id)
      false
  """
  @spec delete_handoff_if_exists(game_id) :: boolean
  def delete_handoff_if_exists(game_id) do
    query = from h in Handoff, where: h.game_id == ^game_id

    case Repo.delete_all(query, await: false) do
      {1, _} -> true
      {0, _} -> false
    end
  end

  @doc """
  Broadcasts a pubsub message on the "handoffs" topic.

  Returns `:ok` if successful, or raises.
  """
  @spec broadcast!(payload :: term) :: :ok
  def broadcast!(payload), do: PubSub.broadcast!(@pubsub, @topic, payload)

  @doc """
  Subscribes to the "handoffs" pubsub topic.
  """
  @spec subscribe :: :ok | {:error, term}
  def subscribe, do: PubSub.subscribe(@pubsub, @topic)
end
