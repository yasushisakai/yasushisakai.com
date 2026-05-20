defmodule YasushisakaiCom.Search do
  import Ecto.Query
  import Pgvector.Ecto.Query

  alias YasushisakaiCom.{Embeddings, NoteEmbedding, Repo, SearchQuery}

  @default_opts [limit: 5, threshold: 1.0, sort: "dist", slugs: nil]

  def search(query_text, opts \\ []) when is_binary(query_text) do
    opts = Keyword.merge(@default_opts, opts)
    normalized = query_text |> String.trim() |> String.downcase()

    if normalized == "" do
      {:ok, []}
    else
      with {:ok, vec} <- embed_query(normalized) do
        {:ok, do_search(vec, opts)}
      end
    end
  end

  defp embed_query(normalized) do
    case Repo.get_by(SearchQuery, query: normalized) do
      # hit
      %SearchQuery{embedding: vec} = sq ->
        sq
        |> Ecto.Changeset.change(
          hit_count: sq.hit_count + 1,
          last_used_at: DateTime.utc_now() |> DateTime.truncate(:second)
        )
        |> Repo.update!()

        {:ok, Pgvector.to_list(vec)}
      # miss
      nil ->
        with {:ok, %{embedding: vec}} <- Embeddings.embed(normalized) do
        %SearchQuery{}
        |> SearchQuery.changeset(%{
          query: normalized,
          embedding: vec,
          hit_count: 1,
          last_used_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
        |> Repo.insert!()
        {:ok, vec}

      end
    end
  end

  defp do_search(vector, opts) do
    limit     = Keyword.fetch!(opts, :limit)
    threshold = Keyword.fetch!(opts, :threshold)
    sort      = Keyword.fetch!(opts, :sort)
    slugs     = Keyword.fetch!(opts, :slugs)

    inner = 
      NoteEmbedding
        |> maybe_filter_slugs(slugs)
        |> select([n], %{
          slug: n.slug,
          distance: cosine_distance(n.embedding, ^vector),
          inserted_at: n.inserted_at
        })

    from(r in subquery(inner),
      where: r.distance <= ^threshold,
      limit: ^limit
    )
    |> order_clause(sort)
    |> Repo.all()

  end

  defp order_clause(query, "dist"), do: order_by(query, [r], asc: r.distance)
  defp order_clause(query, "new"),  do: order_by(query, [r], desc: r.inserted_at)
  defp order_clause(query, "old"),  do: order_by(query, [r], asc: r.inserted_at)
  defp order_clause(query, _),      do: order_by(query, [r], asc: r.distance)

  defp maybe_filter_slugs(query, nil), do: query 
  defp maybe_filter_slugs(query, []), do: query 
  defp maybe_filter_slugs(query, slugs), do: from(n in query, where: n.slug in ^slugs) 

  def slugs_by_date(slugs, direction) when direction in [:asc, :desc] do
    order = [{direction, dynamic([n], n.inserted_at)}]

    from(n in NoteEmbedding,
      where: n.slug in ^slugs,
      order_by: ^order,
      select: n.slug
    ) |> Repo.all()
  end

end
