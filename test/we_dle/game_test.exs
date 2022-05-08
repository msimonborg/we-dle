defmodule WeDle.GameTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  capture_io(fn -> doctest WeDle.Game end)
end
