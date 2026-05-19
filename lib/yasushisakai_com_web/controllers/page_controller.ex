defmodule YasushisakaiComWeb.PageController do
  use YasushisakaiComWeb, :controller

  def home(conn, _params) do
    html_content = YasushisakaiCom.Markdown.content(:about)
    tags = YasushisakaiCom.Markdown.tags(:about)
    YasushisakaiCom.PageVisit.increment("index")
    render(conn, :single_page, content: html_content, tags: tags, lang: "en", show_tags: false)
  end

  def single_page(conn, %{"name" => name}) do
    YasushisakaiCom.PageVisit.increment(name) 
    atom_name = String.to_existing_atom(name)
    html_content = YasushisakaiCom.Markdown.content(atom_name)
    tags = YasushisakaiCom.Markdown.tags(atom_name)
    lang = YasushisakaiCom.Markdown.lang(atom_name)
    render(conn, :single_page, content: html_content, tags: tags, lang: lang, show_tags: true)
  end

  def pages(conn, params) do
    all = parse_tags(params["all"])
    any = parse_tags(params["any"])
    none = parse_tags(params["none"])
    q = params |> Map.get("q", "") |> String.trim()
    
    filtered = YasushisakaiCom.Pages.filter(all: all, any: any, none: none)

    {names, results} = list_or_search(filtered, q)

    # names = Enum.filter(YasushisakaiCom.PageVisit.sorted_slugs(), &(&1 in filtered))

    render(conn, :pages, 
      names: names,
      results: results,
      q: q,
      all: all,
      any: any,
      none: none
    )
  end

  def tags_index(conn, _params) do
    counts = 
      YasushisakaiCom.Pages.tag_counts()
      |> Enum.sort_by(fn {tag, _count} -> tag end)

    render(conn, :tags_index, counts: counts)
  end

  defp list_or_search(filtered, "") do
    names = Enum.filter(YasushisakaiCom.PageVisit.sorted_slugs(), &(&1 in filtered))
    {names, nil}
  end

  defp list_or_search(filtered, q) do
    slugs = Enum.map(filtered, &Atom.to_string/1)

    case YasushisakaiCom.Search.search(q, slugs: slugs, limit: 50) do
      {:ok, results} -> {[], results}
      {:error, _} -> {[], []}
    end

  end

  def parse_tags(nil), do: []
  def parse_tags(""), do: []
  def parse_tags(str) when is_binary(str) do
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.downcase/1)
    |> Enum.reject(&(&1 == ""))
  end

end
