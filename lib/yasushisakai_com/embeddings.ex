defmodule YasushisakaiCom.Embeddings do
  @moduledoc "Wrapper around an OpenAI compatible /v1/embeddings endpoint."

  def embed(text) when is_binary(text) do
    cfg = Application.fetch_env!(:yasushisakai_com, :embeddings)
    url = cfg[:base_url] <> "/v1/embeddings"
    body = %{model: cfg[:model], input: text}

    started = System.monotonic_time(:millisecond)

    case Req.post(url, json: body, receive_timeout: 60_000) do
        {:ok, %{status: 200, body: %{"data" => [%{"embedding" => v} | _]}, }} -> 
        elapsed = System.monotonic_time(:millisecond) - started
        {:ok, %{embedding: v, elapsed_ms: elapsed}}

        {:ok, %{status: s, body: b}} -> {:error, {:http, s, b}}

        {:error, e} -> {:error, e}
    end
  end
end
