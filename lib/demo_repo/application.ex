defmodule DemoRepo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DemoRepoWeb.Telemetry,
      DemoRepo.Repo,
      {DNSCluster, query: Application.get_env(:demo_repo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DemoRepo.PubSub},
      # Start a worker by calling: DemoRepo.Worker.start_link(arg)
      # {DemoRepo.Worker, arg},
      # Start to serve requests, typically the last entry
      DemoRepoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DemoRepo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DemoRepoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
