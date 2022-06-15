defmodule WeDle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor, [topologies(), [name: WeDle.ClusterSupervisor]]},
      Fly.RPC,
      WeDle.Repo.Local,
      {Fly.Postgres.LSN.Tracker, repo: WeDle.Repo.Local},
      WeDleWeb.Telemetry,
      {Phoenix.PubSub, name: WeDle.PubSub},
      WeDle.WordleWords,
      WeDle.Game.Supervisor,
      WeDleWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: WeDle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WeDleWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @doc """
  Returns the runtime environment as configured in `config/config.exs`
  by `Config.config_env/0`.
  """
  def runtime_env, do: Application.get_env(:we_dle, :runtime_env)

  # libcluster clustering topologies
  defp topologies do
    Application.get_env(:libcluster, :topologies) || []
  end
end
