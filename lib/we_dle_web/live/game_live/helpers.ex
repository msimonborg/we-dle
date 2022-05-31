defmodule WeDleWeb.GameLive.Helpers do
  @moduledoc """
  Presentation helper functions.
  """

  def background_color("light"), do: "bg-zinc-100"
  def background_color("dark"), do: "bg-zinc-900"

  def border_color("light"), do: "border-zinc-300"
  def border_color("dark"), do: "border-zinc-700"

  def text_color("light"), do: "text-zinc-900"
  def text_color("dark"), do: "text-zinc-100"

  def hover_text_color("light"), do: "hover:text-zinc-700"
  def hover_text_color("dark"), do: "hover:text-zinc-200"
end
