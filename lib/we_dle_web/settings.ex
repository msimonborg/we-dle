defmodule WeDleWeb.Settings do
  @moduledoc """
  An embedded schema and associated functions for transforming
  and validating user settings.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias WeDle.Game

  @fields [
    :player_id,
    :dark_theme,
    :hard_mode,
    :high_contrast
  ]

  @primary_key false

  @derive {Phoenix.Param, key: :player_id}

  embedded_schema do
    field :player_id, :string
    field :dark_theme, :integer
    field :hard_mode, :integer
    field :high_contrast, :integer
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_inclusion(:dark_theme, [0, 1])
    |> validate_inclusion(:hard_mode, [0, 1])
    |> validate_inclusion(:high_contrast, [0, 1])
    |> validate_length(:player_id, is: 36)
  end

  def new(attrs \\ %{}) do
    %__MODULE__{
      player_id: Game.unique_id(),
      dark_theme: attrs[:dark_theme] || 0,
      hard_mode: attrs[:hard_mode] || 0,
      high_contrast: attrs[:high_contrast] || 0
    }
  end
end
