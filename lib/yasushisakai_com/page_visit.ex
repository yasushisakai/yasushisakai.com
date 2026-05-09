defmodule YasushisakaiCom.PageVisit do
  use Ecto.Schema

  schema "page_visits" do
    field :slug, :string
    field :count, :integer, default: 0
  end

  import Ecto.Query

  def increment(slug) do
    YasushisakaiCom.Repo.insert(
      %__MODULE__{slug: slug, count: 1},
      on_conflict: [inc: [count: 1]],
      conflict_target: :slug
    )
  end

  @blacklist ~w(index)a

  def sorted_slugs do

    visited = 
      from(p in __MODULE__, order_by: [desc: p.count], select: p.slug )
      |> YasushisakaiCom.Repo.all()
      |> Enum.map(&String.to_existing_atom/1)
      |> Enum.reject(&(&1 in @blacklist))

    all = YasushisakaiCom.Markdown.all_names()

    visited ++ (all -- visited)
  end

end
