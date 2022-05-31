defmodule WeDleWeb.LiveHelpers do
  @moduledoc """
  Presentation helper functions.
  """

  def background_color(0 = _dark_theme), do: "bg-zinc-100"
  def background_color(1 = _dark_theme), do: "bg-zinc-900"

  def border_color(0 = _dark_theme), do: "border-zinc-300"
  def border_color(1 = _dark_theme), do: "border-zinc-700"

  def text_color(0 = _dark_theme), do: "text-zinc-900"
  def text_color(1 = _dark_theme), do: "text-zinc-100"

  def hover_text_color(0 = _dark_theme), do: "hover:text-zinc-700"
  def hover_text_color(1 = _dark_theme), do: "hover:text-zinc-200"

  def divide_color(0 = _dark_theme), do: "divide-zinc-300"
  def divide_color(1 = _dark_theme), do: "divide-zinc-700"
end
