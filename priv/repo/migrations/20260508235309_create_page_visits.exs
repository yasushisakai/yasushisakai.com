defmodule YasushisakaiCom.Repo.Migrations.CreatePageVisits do
  use Ecto.Migration

  def change do
    create table(:page_visits) do
      add :slug, :string, null: false
      add :count, :integer, default: 0, null: false
    end

    create unique_index(:page_visits, [:slug])
  end

end
