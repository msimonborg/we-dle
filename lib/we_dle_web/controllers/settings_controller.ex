defmodule WeDleWeb.SettingsController do
  @moduledoc """
  Functions to transform and store player data in browser cookies.
  """

  use WeDleWeb, :controller

  import Plug.Conn

  alias WeDleWeb.Settings

  # Make the cookie valid for 60 days.
  @max_age 60 * 60 * 24 * 60
  @cookie "_we_dle_web_settings"
  @cookie_options [sign: true, max_age: @max_age, same_site: "Lax"]

  def update(conn, %{"settings" => settings_params}) do
    settings =
      conn
      |> fetch_session()
      |> get_session(:settings)

    changeset = Settings.changeset(settings, settings_params)

    if changeset.valid? do
      settings = Ecto.Changeset.apply_changes(changeset)

      conn
      |> put_resp_cookie(@cookie, settings, @cookie_options)
      |> put_session(:settings, settings)
      |> html("ok")
    else
      errors =
        Enum.map_join(changeset.errors, ", ", fn {field, {reason, _}} ->
          "#{field} #{reason}"
        end)

      conn
      |> put_status(:unprocessable_entity)
      |> html("errors: #{errors}")
    end
  end

  def fetch_or_store_settings(conn, _opts) do
    conn = fetch_cookies(conn, signed: [@cookie])

    settings =
      case conn.cookies[@cookie] do
        nil ->
          Settings.new()

        settings when is_struct(settings, Settings) ->
          # Make sure the settings in the browser are always up to
          # date with the current version of the Settings struct.
          # If they are not valid, replace them!
          changeset = Settings.changeset(Settings.new(), Map.from_struct(settings))
          if changeset.valid?, do: Ecto.Changeset.apply_changes(changeset), else: Settings.new()
      end

    conn
    |> put_resp_cookie(@cookie, settings, @cookie_options)
    |> put_session(:settings, settings)
  end

  @doc """
  The name of the settings cookie storage key.
  """
  def cookie, do: @cookie
end
