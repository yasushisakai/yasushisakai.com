defmodule YasushisakaiCom.Repo do
  use Ecto.Repo,
    otp_app: :yasushisakai_com,
    adapter: Ecto.Adapters.Postgres
end
