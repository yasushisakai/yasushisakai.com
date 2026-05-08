defmodule YasushisakaiComWeb.PageController do
  use YasushisakaiComWeb, :controller

  def home(conn, _params) do
    html_content = YasushisakaiCom.Markdown.content(:about)
    render(conn, :single_page, content: html_content)
  end

  def single_page(conn, %{"name" => name}) do
    atom_name = String.to_existing_atom(name)
    html_content = YasushisakaiCom.Markdown.content(atom_name)
    render(conn, :single_page, content: html_content)
  end

  def pages(conn, _params) do
    render(conn, :pages, names: YasushisakaiCom.Markdown.all_names())
  end

end
