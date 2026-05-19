defmodule YasushisakaiComWeb.PagesLive do
  use YasushisakaiComWeb, :live_view

  alias YasushisakaiCom.{Markdown, Pages, PageVisit, Search}
  import YasushisakaiComWeb.PageHTML, only: [filter_without: 6]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
      assign(socket,
        q: "",
        all: [],
        any: [],
        none: [],
        results: nil
      )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    all = parse_tags(params["all"])
    any = parse_tags(params["any"])
    none = parse_tags(params["none"])
    q = params |> Map.get("q", "") |> String.trim()
    l = params |> Map.get("l", "50") |> parse_int(50, 1, 200)
    t = params |> Map.get("t", "1.0") |> parse_float(1.0, 0.0, 2.0)
    sort = Map.get(params, "sort", "dist")

    filtered = Pages.filter(all: all, any: any, none: none)
    {names, results} = list_or_search(filtered, q, limit: l, threshold: t, sort: sort)

    {:noreply, 
      assign(socket, q: q, all: all, any: any, none: none, 
      limit: l, threshold: t, sort: sort,
      names: names, results: results
      )}
  end

  defp parse_tags(nil), do: []
  defp parse_tags(""), do: []
  defp parse_tags(str) when is_binary(str) do
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.downcase/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp list_or_search(filtered, "", _opts) do
    names = Enum.filter(PageVisit.sorted_slugs(), &(&1 in filtered))
    {names, nil}
  end

  defp list_or_search(filtered, q, opts) do
    slugs = Enum.map(filtered, &Atom.to_string/1)
    opts = Keyword.put(opts, :slugs, slugs)

    case Search.search(q, opts) do
      {:ok, results} -> {[], results}
      {:error, _} -> {[], []}
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
  def handle_event("search", %{"q" => q}, socket) do
    params = 
      [q: q]
      |> add_params(:all, socket.assigns.all)
      |> add_params(:any, socket.assigns.any)
      |> add_params(:none, socket.assigns.none)
      |> Keyword.put(:l, socket.assigns.limit)
      |> Keyword.put(:t, socket.assigns.threshold)
      |> Keyword.put(:sort, socket.assigns.sort)

    {:noreply, push_patch(socket, to: ~p"/pages?#{params}", replace: true)}
  end

  defp add_params(acc, _key, []), do: acc
  defp add_params(acc, key, list), do: acc ++ [{key, Enum.join(list, ",")}]
   
  @impl true
  def render(assigns) do
  ~H"""
  <div class="flex flex-col space-y-3">
    <!-- Search -->
    <div>
    <form phx-change="search">
          <input
            class="text-lg placeholder:italic placeholder:text-slate-400 block w-full border border-slate-300 rounded-md p-3 focus:outline-none focus:ring-slate-400
  focus:ring-1"
            type="text"
            name="q"
            value={@q}
            placeholder="Search notes..."
            phx-debounce="200"
            autocomplete="off"
            autofocus
          />
    </form>
    <p><small>l={@limit} t={@threshold} sort={@sort}</small></p>
    </div>

    <!-- Filtering-->
    <div :if={@all !=[] or @any !=[] or @none !=[]} class="flex flex-wrap gap-2 items-center">
      <b>Filtering</b>
      <a 
        :for={tag <- @all}
        href={~p"/pages?#{filter_without(@all, @any, @none, @q, :all, tag)}"}
        class="text-xs px-2 py-1 rounded bg-emerald-100 hover:bg-emerald-200 no-underline"
        title="Click to remote from 'all'"
      >all: {tag} ×</a>

      <a 
        :for={tag <- @any}
        href={~p"/pages?#{filter_without(@all, @any, @none, @q, :any, tag)}"}
        class="text-xs px-2 py-1 rounded bg-emerald-100 hover:bg-emerald-200 no-underline"
        title="click to remote from 'any'"
      >any: {tag} ×</a>

      <a 
        :for={tag <- @none}
        href={~p"/pages?#{filter_without(@all, @any, @none, @q, :none, tag)}"}
        class="text-xs px-2 py-1 rounded bg-emerald-100 hover:bg-emerald-200 no-underline"
        title="click to remote from 'none'"
      >none: {tag} ×</a>

    </div>


    <!-- List -->
    <div>
      <%= if is_nil(@results) do %>
        <!-- just tags -->
        <ul :if={@names != []} class="list-none p-0 grid grid-cols-[max-content_1fr] gap-x-4 gap-y-1 items-baseline">
          <li class="contents text-sm uppercase tracking-white opacity-60">
            <span class="pl-1">Name</span>
            <span><a href="/tags">Tags</a></span>
          </li>
          <li :for={name <- @names} class="contents">
            <a href={~p"/pages/#{name}"}>{name}</a>
            <div class="flex flex-wrap gap-1">
              <a :for={tag <- Markdown.tags(name)}
                href={~p"/pages?#{[all: tag]}"}
                class="text-xs px-1.5 py-0.5 rounded bg-base-200 hover:bg-[var(--yasushi-yellow)] hover:text-[oklch(20%_0_0)] no-underline"
              >{tag}</a>
            </div>
          </li>
        </ul>
        <p :if={@names == []}>No notes match.</p>
      <% else %>
        <!-- search + tags -->
        <ul :if={@results != []} class="list-none p-0 grid grid-cols-[max-content_max-content_1fr] gap-x-4 gap-y-1 items-baseline">
          <li class="contents text-sm uppercase tracking-white opacity-60">
            <span class="pl-1">Name</span>
            <span>Dist</span>
            <span><a href="/tags">Tags</a></span>
          </li>
          <li :for={r <- @results} class="contents">
            <a href={~p"/pages/#{r.slug}"}>{r.slug}</a>
            <small class="font-mono">{Float.round(r.distance, 3)}</small>
            <div class="flex flex-wrap gap-1">
              <a :for={tag <- Markdown.tags(String.to_existing_atom(r.slug))}
                href={~p"/pages?#{[all: tag]}"}
                class="text-xs px-1.5 py-0.5 rounded bg-base-200 hover:bg-[var(--yasushi-yellow)] hover:text-[oklch(20%_0_0)] no-underline"
              >{tag}</a>
            </div>
          </li>
        </ul>
        <p :if={@results == []}>No matches for "{@q}".</p>
      <% end %>
    </div>
  </div>
  """
  end
end
