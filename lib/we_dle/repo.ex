defmodule WeDle.Repo do
  use Ecto.Repo,
    otp_app: :we_dle,
    adapter: Ecto.Adapters.Postgres
end
