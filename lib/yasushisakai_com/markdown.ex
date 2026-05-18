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

    {fm, body} = 
      case raw do
        "---\n" <> rest ->
          case String.split(rest, ~r/\n---\n/, parts: 2) do
            [fm, b] -> {fm, b}
            _ -> {"", "---\n" <> rest}
          end
        _ -> {"", raw}
      end

    tags = 
      fm 
      |> String.split("\n")
      |> Enum.find_value([], fn line ->
        case line |> String.trim() |> String.split(":", parts: 2) do
          ["tags", rest] ->
            rest
            |> String.split(",")
            |> Enum.map(&String.trim/1)
            |> Enum.map(&String.downcase/1)
            |> Enum.reject(&(&1 == ""))
            |> Enum.sort()
          _ -> 
            nil
        end
      end)

    lang_value = 
      case Enum.find(tags, &String.starts_with?(&1, "lang:")) do
        "lang:" <> v -> v
        _ -> "ja"
      end

    hash = :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)

    html = 
      body
      |> Earmark.as_html!(%Earmark.Options{footnotes: true, gfm_tables: true, breaks: true})
      |> String.replace(~s(src="images/), ~s(src="/images/))

    def content(unquote(name)), do: unquote(html)
    def raw(unquote(name)), do: unquote(body)
    def content_hash(unquote(name)), do: unquote(hash)
    def tags(unquote(name)), do: unquote(tags)
    def lang(unquote(name)), do: unquote(lang_value)

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
