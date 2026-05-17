defmodule YasushisakaiCom.Repo.Migrations.CreateNoteEmbeddings do
  use Ecto.Migration

  def change do

    create table(:note_embeddings) do
      add :slug, :string, null: false
      add :content_hash, :string, null: false
      add :embedding, :vector, size: 4096
      timestamps(type: :utc_datetime)
    end

    create unique_index(:note_embeddings, [:slug])
  end
end
