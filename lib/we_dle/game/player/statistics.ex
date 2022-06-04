defmodule WeDle.Game.Player.Statistics do
  @moduledoc """
  Calculate and operate on a player's statistics.
  """

  defstruct last_result: :none,
            played: 0,
            wins: 0,
            draws: 0,
            current_streak: 0,
            max_streak: 0,
            guesses: %{1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0}

  @type t :: %__MODULE__{
          last_result: :won | :lost | :draw | :none,
          played: non_neg_integer,
          wins: non_neg_integer,
          draws: non_neg_integer,
          current_streak: non_neg_integer,
          max_streak: non_neg_integer,
          guesses: %{
            1 => non_neg_integer,
            2 => non_neg_integer,
            3 => non_neg_integer,
            4 => non_neg_integer,
            5 => non_neg_integer,
            6 => non_neg_integer
          }
        }

  @doc """
  Produces a new `WeDle.Game.Statistics` struct.
  """
  def new, do: %__MODULE__{}
end
