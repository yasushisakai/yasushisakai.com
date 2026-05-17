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

    hash = :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)

    html = 
      body
      |> Earmark.as_html!(%Earmark.Options{footnotes: true})
      |> String.replace(~s(src="images/), ~s(src="/images/))

    def content(unquote(name)), do: unquote(html)
    def raw(unquote(name)), do: unquote(body)
    def content_hash(unquote(name)), do: unquote(hash)

  end

  def all_names do
    unquote(
      @public_files
      |> Enum.map(&(&1 |> Path.basename(".md") |> String.downcase() |> String.to_atom()))
    )
  end

  def public_entries do
    Enum.map(all_names(), fn name -> 
      %{name: name, raw: raw(name), hash: content_hash(name)}
    end)
  end

end
