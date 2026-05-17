defmodule YasushisakaiCom.Repo.Migrations.CreateSearchQueries do
  use Ecto.Migration

  def change do
    create table(:search_queries) do
      add :query, :string, null: false
      add :embedding, :vector, size: 4096
      add :hit_count, :integer, null: false, default: 1
      add :last_used_at, :utc_datetime, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:search_queries, [:query])
  end
end
