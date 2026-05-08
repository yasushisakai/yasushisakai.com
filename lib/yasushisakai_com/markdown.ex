defmodule YasushisakaiCom.Markdown do
  @markdown_dir Path.expand("../../markdown", __DIR__)
  @markdown_files Path.wildcard(Path.join(@markdown_dir, "*.md"))

  for file <- @markdown_files do
    @external_resource file

    name = 
      file
      |> Path.basename(".md")
      |> String.downcase()
      |> String.to_atom()

    html = 
    file 
    |> File.read!() 
    |> Earmark.as_html!()
    |> String.replace(~s(src="images/), ~s(src="/images/))

    def content(unquote(name)), do: unquote(html)
  end

  def all_names do
    unquote(
      @markdown_files
      |> Enum.map(&(&1 |> Path.basename(".md") |> String.downcase() |> String.to_atom()))
    )
  end
end
