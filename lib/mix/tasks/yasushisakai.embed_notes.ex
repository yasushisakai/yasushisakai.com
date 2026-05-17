defmodule Mix.Tasks.Yasushisakai.EmbedNotes do

  use Mix.Task

  @shortdoc "Embed all public markdown files into note_embeddings table. Skips if unchanged."

  alias YasushisakaiCom.{Embeddings, Markdown, NoteEmbedding, Repo}

  @impl true

  def run(_args) do 
    Mix.Task.run("app.start")
    Markdown.public_entries() |> Enum.each(&process/1)
  end

  defp process(%{name: name, raw: raw, hash: hash}) do
    slug = Atom.to_string(name)

    case Repo.get_by(NoteEmbedding, slug: slug) do
      %NoteEmbedding{content_hash: ^hash} ->
        Mix.shell().info("skip #{slug} (same hash)")

      existing ->
        Mix.shell().info("embed #{slug} ...")

        case Embeddings.embed(raw) do
          {:ok, %{embedding: vec, elapsed_ms: ms}} -> 
            Mix.shell().info("  (#{ms} ms)")
            attrs = %{slug: slug, content_hash: hash, embedding: vec}

            result = 
              case existing do
                nil -> %NoteEmbedding{} |> NoteEmbedding.changeset(attrs) |> Repo.insert()
                row -> row |> NoteEmbedding.changeset(attrs) |> Repo.update()
              end

            case result do
              {:ok, _}    -> Mix.shell().info("ok #{slug}")
              {:error, e} -> Mix.shell().error("fail #{slug}: #{inspect(e)}")
            end

            {:error, e} ->
             Mix.shell().error("embed-fail #{slug}: #{inspect(e)}")
          end
    end
  end

end
