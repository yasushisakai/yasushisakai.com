defmodule YasushisakaiCom.NoteEmbedding do
  use Ecto.Schema
  import Ecto.Changeset

  schema "note_embeddings" do 
    field :slug, :string
    field :content_hash, :string
    field :embedding, Pgvector.Ecto.Vector
    timestamps(type: :utc_datetime)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:slug, :content_hash, :embedding])
    |> validate_required([:slug, :content_hash, :embedding])
    |> unique_constraint(:slug)
  end
end
