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
    sort = coerce_sort(q, Map.get(params, "sort"))

    filtered = Pages.filter(all: all, any: any, none: none)
    {names, results} = list_or_search(filtered, q, limit: l, threshold: t, sort: sort)

    # FIXME: do we need sorted_slugs?
    total = length(PageVisit.sorted_slugs())

    {:noreply, 
      assign(socket, q: q, all: all, any: any, none: none, 
      limit: l, threshold: t, sort: sort,
      names: names, results: results,
      total: total
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

  # when q is empty -> tag-filtering browse mode
  defp list_or_search(filtered, "", opts) do
    names = browse_names(filtered, Keyword.fetch!(opts, :sort), Keyword.fetch!(opts, :limit))
    {names, nil}
  end
  
  # search mode, cosine similarity mode is applied
  defp list_or_search(filtered, q, opts) do
    slugs = Enum.map(filtered, &Atom.to_string/1)
    requested_sort = Keyword.fetch!(opts, :sort)

    search_opts = 
      opts
      |> Keyword.put(:slugs, slugs)
      |> Keyword.put(:sort, db_sort(requested_sort))

    case Search.search(q, search_opts) do
      {:ok, results} -> {[], reorder(results, requested_sort)}
      {:error, _} -> {[], []}
    end
  end

  defp db_sort("visits"), do: "dist"
  defp db_sort(o), do: o

  defp reorder(results, "visits") do
    rank = 
      PageVisit.sorted_slugs()
      |> Enum.with_index()
      |> Map.new(fn {slug, i} -> {Atom.to_string(slug), i} end)
    Enum.sort_by(results, fn r -> Map.get(rank, r.slug, 1_000_000) end)
  end

  defp reorder(results, _), do: results

  defp browse_names(filtered, "visits", limit) do
    PageVisit.sorted_slugs()
    |> Enum.filter(&(&1 in filtered))
    |> Enum.take(limit)
  end

  defp browse_names(filtered, sort, limit) when sort in ["new", "old"] do
    direction = if sort =="new", do: :desc, else: :asc
    slugs = Enum.map(filtered, &Atom.to_string/1)

    Search.slugs_by_date(slugs, direction)
    |> Enum.take(limit)
    |> Enum.map(&String.to_existing_atom/1)

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

  defp coerce_sort("", s) when s in ~w(visits new old), do: s
  defp coerce_sort("", _), do: "visits"
  defp coerce_sort(_q, s) when s in ~w(dist visits new old), do: s
  defp coerce_sort(_q, _), do: "dist"

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    sort = coerce_sort(q, socket.assigns.sort)

    params = 
      [q: q]
      |> add_params(:all, socket.assigns.all)
      |> add_params(:any, socket.assigns.any)
      |> add_params(:none, socket.assigns.none)
      |> Keyword.put(:l, socket.assigns.limit)
      |> Keyword.put(:t, socket.assigns.threshold)
      |> Keyword.put(:sort, sort)

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
  fo  cus:ring-1"
              type="text"
              name="q"
              value={@q}
              placeholder="Search notes..."
              phx-debounce="200"
              autocomplete="off"
              autofocus
            />
      </form>
      <div class="flex justify-between items-baseline text-sm text-slate-500">
        <span>{mode_header(assigns)}</span>
        <a href={~p"/pages/how_to_use"} class="underline no-underline hover:underline">How to use</a>
      </div>
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
        <ul :if={@names != []} class="list-none p-0 grid grid-cols-[max-content_1fr] gap-x-4 gap-y-3 items-start">
          <li class="contents text-sm uppercase tracking-white opacity-60">
            <span class="pl-1">Name</span>
            <span><a href="/tags">Tags</a></span>
          </li>
          <li :for={name <- @names} class="contents">
            <div>
              <a href={~p"/pages/#{name}"} class="font-medium">{Markdown.title(name)}</a>
              <span class="text-xs opacity-50 font-mono">{name}</span>
            </div>
            <div class="flex flex-wrap gap-1">
              <a :for={tag <- Markdown.tags(name)}
                href={~p"/pages?#{[all: tag]}"}
                class="text-xs px-1.5 py-0.5 rounded bg-base-200 hover:bg-[var(--yasushi-yellow)] hover:text-[oklch(20%_0_0)] no-underline"
              >{tag}</a>
            </div>
          </li>
        </ul>
      <% else %>
        <!-- search + tags -->
        <ul :if={@results != []} class="list-none p-0 grid grid-cols-[max-content_max-content_1fr] gap-x-4 gap-y-3 items-start">
          <li class="contents text-sm uppercase tracking-white opacity-60">
            <span class="pl-1">Name</span>
            <span>Dist</span>
            <span><a href="/tags">Tags</a></span>
          </li>
          <li :for={r <- @results} class="contents">
            <div>
              <a href={~p"/pages/#{r.slug}"} class="font-medium">{Markdown.title(String.to_existing_atom(r.slug))}</a>
              <span class="text-xs opacity-50 font-mono">{r.slug}</span>
            </div>
            <small class="font-mono">{Float.round(r.distance, 3)}</small>
            <div class="flex flex-wrap gap-1">
              <a :for={tag <- Markdown.tags(String.to_existing_atom(r.slug))}
                href={~p"/pages?#{[all: tag]}"}
                class="text-xs px-1.5 py-0.5 rounded bg-base-200 hover:bg-[var(--yasushi-yellow)] hover:text-[oklch(20%_0_0)] no-underline"
              >{tag}</a>
            </div>
          </li>
        </ul>
      <% end %>
    </div>
  </div>
  """
  end

defp mode_header(%{q: "", names: []}), do: "No notes match"

defp mode_header(%{q: "", names: names, total: total, sort: sort}) do
  count_str = if length(names) == total, do: "#{total}", else: "#{length(names)} of #{total}"
  "Browsing #{count_str} notes. Sorted by #{sort_label(sort)}"
end

defp mode_header(%{results: [], q: q}), do: ~s(No matches for "#{q}")

defp mode_header(%{results: results, q: q, sort: sort}) do
  ~s(#{length(results)} results for "#{q}". Sorted by #{sort_label(sort)})
end

defp sort_label("visits"), do: "visits"
defp sort_label("dist"), do: "similarity"
defp sort_label("new"), do: "latest first"
defp sort_label("old"), do: "oldest first"

end
