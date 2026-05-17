defmodule YasushisakaiCom.SearchQuery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "search_queries" do
    field :query, :string
    field :embedding, Pgvector.Ecto.Vector
    field :hit_count, :integer, default: 1
    field :last_used_at, :utc_datetime
    timestamps(type: :utc_datetime)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:query, :embedding, :hit_count, :last_used_at])
    |> validate_required([:query, :embedding, :last_used_at])
    |> unique_constraint(:query)
  end

end
