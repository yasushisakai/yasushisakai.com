defmodule YasushisakaiComWeb.PageController do
  use YasushisakaiComWeb, :controller

  def home(conn, _params) do
    html_content = YasushisakaiCom.Markdown.content(:about)
    tags = YasushisakaiCom.Markdown.tags(:about)
    YasushisakaiCom.PageVisit.increment("index")
    render(conn, :single_page, content: html_content, tags: tags)
  end

  def single_page(conn, %{"name" => name}) do
    YasushisakaiCom.PageVisit.increment(name) 
    atom_name = String.to_existing_atom(name)
    html_content = YasushisakaiCom.Markdown.content(atom_name)
    tags = YasushisakaiCom.Markdown.tags(atom_name)
    render(conn, :single_page, content: html_content, tags: tags)
  end

  def pages(conn, params) do
    all = parse_tags(params["all"])
    any = parse_tags(params["any"])
    none = parse_tags(params["none"])
    
    names = YasushisakaiCom.Pages.filter(all: all, any: any, none: none)

    render(conn, :pages, 
      # FIXME: dropping this for now
      # names: YasushisakaiCom.PageVisit.sorted_slugs()
      names: names,
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
