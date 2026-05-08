defmodule YasushisakaiCom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      YasushisakaiComWeb.Telemetry,
      YasushisakaiCom.Repo,
      {DNSCluster, query: Application.get_env(:yasushisakai_com, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: YasushisakaiCom.PubSub},
      # Start a worker by calling: YasushisakaiCom.Worker.start_link(arg)
      # {YasushisakaiCom.Worker, arg},
      # Start to serve requests, typically the last entry
      YasushisakaiComWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: YasushisakaiCom.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    YasushisakaiComWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
