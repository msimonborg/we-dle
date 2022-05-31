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
    :theme,
    :hard_mode,
    :high_contrast
  ]

  @primary_key false

  @derive {Phoenix.Param, key: :player_id}

  embedded_schema do
    field :player_id, :string
    field :theme, :string
    field :hard_mode, :boolean
    field :high_contrast, :boolean
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_length(:player_id, is: 36)
    |> validate_inclusion(:theme, ["light", "dark"])
  end

  def new(attrs \\ %{}) do
    %__MODULE__{
      player_id: Game.unique_id(),
      theme: attrs[:theme] || "light",
      hard_mode: attrs[:hard_mode] || false,
      high_contrast: attrs[:high_contrast] || false
    }
  end
end
