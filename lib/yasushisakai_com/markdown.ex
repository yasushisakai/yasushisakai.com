defmodule YasushisakaiCom.Markdown do
  @markdown_dir Path.expand("../../markdown", __DIR__)
  @markdown_files Path.wildcard(Path.join(@markdown_dir, "*.md"))

  @public_files Enum.filter(@markdown_files, fn file -> 
    file |> File.read!() |> String.starts_with?("---\n") and
    file |> File.read!() |> String.contains?("public: true")
  end)

  for file <- @public_files do
    @external_resource file

    name = 
      file
      |> Path.basename(".md")
      |> String.downcase()
      |> String.to_atom()

    raw = File.read!(file)

    body =
      case raw do
        "---\n" <> rest ->
          case String.split(rest, ~r/\n---\n/, parts: 2) do
            [_fm, b] -> b
            _ -> "---\n" <> rest
          end
        _ -> raw
      end

      html = 
        body
        |> Earmark.as_html!()
        |> String.replace(~s(src="images/), ~s(src="/images/))

    def content(unquote(name)), do: unquote(html)
  end

  def all_names do
    unquote(
      @public_files
      |> Enum.map(&(&1 |> Path.basename(".md") |> String.downcase() |> String.to_atom()))
    )
  end
end
