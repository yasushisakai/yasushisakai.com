defmodule YasushisakaiComWeb.SearchLive do
  use YasushisakaiComWeb, :live_view
  alias YasushisakaiCom.Search

  @impl true
  def mount(_params, _session, socket) do
    {:ok, 
      assign(socket, 
        query: "", 
        limit: 5,
        threshold: 1.0,
        sort: "dist",
        results: [], 
        error: nil
      )}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    params = [
      q: q, 
      l: to_string(socket.assigns.limit), 
      t: to_string(socket.assigns.threshold), 
      s: socket.assigns.sort
    ]

    {:noreply, push_patch(socket, to: ~p"/search?#{params}", replace: true)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    q = Map.get(params, "q", "")
    l = params |> Map.get("l", "5")   |> parse_int(5, 1, 50)
    t = params |> Map.get("t", "1.0") |> parse_float(1.0, 0.0, 2.0) 
    s = Map.get(params, "sort", "dist")

    case Search.search(q, limit: l, threshold: t, sort: s) do
      {:ok, results} ->
        {:noreply, assign(socket, query: q, limit: l, threshold: t, sort: s, results: results, error: nil)}

      {:error, e} ->
        {:noreply, assign(socket, query: q, limit: l, threshold: t, sort: s, results: [], error: inspect(e))}
    end
  end

  defp parse_int(str, default, min, max) when is_binary(str) do
    case Integer.parse(str) do
      {n, ""} when n >= min and n <= max -> n
      _ -> default
    end
  end

  defp parse_float(str, default, min, max) when is_binary(str) do
    case Float.parse(str) do
      {n, ""} when n >= min and n <= max -> n
      _ -> default
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form phx-change="search">
      <input 
      class = "text-lg 
               placeholder:italic
               placeholder:text-slate-400 
               block 
               w-full 
               border 
               border-slate-300 
               rounded-md 
               p-3 
               focus:outline-none  
               focus:ring-slate-400 
               focus:ring-1"
  
        type="text"
        name="q"
        value={@query}
        placeholder="Search notes..."
        phx-debounce="200"
        autocomplete="off"
        autofocus
      />
    </form>

    <p><small>l={@limit} t={@threshold} s={@sort}</small></p>

    <p :if={@error}>error: {@error}</p>

    <ul :if={@results != []} class="list-none p-0 grid grid-cols-[max-content_1fr] gap-x-4 gap-y-1 items-baseline">
      <li :for={r <- @results} class="contents">
        <a class="no-underline" href={~p"/pages/#{r.slug}"}>{r.slug}</a>
        <small class="font-mono">{Float.round(r.distance, 3)}</small>
      </li>
    </ul>

    <p :if={@query != "" and @results == [] and is_nil(@error)}>No maches.</p>
    """
  end

end
