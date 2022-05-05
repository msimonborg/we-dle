defmodule WeDle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # setup for clustering
        {Cluster.Supervisor, [topologies(), [name: WeDle.ClusterSupervisor]]},
        # Start distributed registry
        WeDle.DistributedRegistry,
        # Start distributed supervisor
        WeDle.DistributedSupervisor,
        # Start the node listener
        WeDle.NodeListener,
        # Start the Ecto repository
        WeDle.Repo,
        # Start the Telemetry supervisor
        WeDleWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: WeDle.PubSub},
        # Start the Endpoint (http/https)
        WeDleWeb.Endpoint
        # Start a worker by calling: WeDle.Worker.start_link(arg)
        # {WeDle.Worker, arg}
      ] ++ start_finch_in_prod()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
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

  # only start Finch for mailers in production
  defp start_finch_in_prod do
    if runtime_env() == :prod, do: [{Finch, name: WeDle.Mailer.Finch}], else: []
  end
end
