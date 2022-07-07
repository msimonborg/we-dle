defmodule WeDleWeb.LiveHelpers do
  @moduledoc """
  Presentation helper functions.
  """

  def text_color, do: "text-zinc-900 dark:text-zinc-100"
  def background_color, do: "bg-zinc-100 dark:bg-zinc-900"
  def border_color, do: "border-zinc-300 dark:border-zinc-700"
  def divide_color, do: "divide-zinc-300 dark:divide-zinc-700"
  def hover_text_color, do: "hover:text-zinc-700 dark:hover:text-zinc-300"
end
