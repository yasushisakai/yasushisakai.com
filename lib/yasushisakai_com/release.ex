defmodule YasushisakaiCom.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :yasushisakai_com

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed_embeddings() do
    load_app()
    {:ok, _, _} = 
      Ecto.Migrator.with_repo(YasushisakaiCom.Repo, fn _repo ->
        {:ok, _} = Application.ensure_all_started(:req)
        YasushisakaiCom.Markdown.public_entries()
        |> Enum.each(&seed_one/1)
      end)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    # Many platforms require SSL when connecting to the database
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)
  end

  defp seed_one(%{name: name, raw: raw, hash: hash}) do
    alias YasushisakaiCom.{Embeddings, NoteEmbedding, Repo}
    slug = Atom.to_string(name)

    case Repo.get_by(NoteEmbedding, slug: slug) do
      %NoteEmbedding{content_hash: ^hash} ->
        IO.puts("skip   #{slug}")

      existing ->
        IO.puts("embed  #{slug} ...")
        case Embeddings.embed(raw) do
          {:ok, %{embedding: vec}} ->
            attrs = %{slug: slug, content_hash: hash, embedding: vec}

            result = 
              case existing do
                nil -> %NoteEmbedding{} |> NoteEmbedding.changeset(attrs) |> Repo.insert()
                row -> row |> NoteEmbedding.changeset(attrs) |> Repo.update()
              end

           case result do
             {:ok, _}      -> IO.puts("ok    #{slug}")
             {:error, e}   -> IO.puts("fail  #{slug}: #{inspect(e)}")
           end

          {:error, e} ->
            IO.puts("embed-fail #{slug}: #{inspect(e)}")
        end
    end
  end

end
