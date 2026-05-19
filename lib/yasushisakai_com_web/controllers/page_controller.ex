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

  def tags_index(conn, _params) do
    counts = 
      YasushisakaiCom.Pages.tag_counts()
      |> Enum.sort_by(fn {tag, _count} -> tag end)

    render(conn, :tags_index, counts: counts)
  end

end
