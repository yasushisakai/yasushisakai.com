defmodule YasushisakaiComWeb.Plugs.MarkdownImages do
  use Plug.Builder

  plug Plug.Static,
    at: "/images",
    from: Path.expand("../../../markdown/images", __DIR__),
    gzip: false
end
