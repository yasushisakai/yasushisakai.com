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

    all = YasushisakaiCom.Markdown.all_names() -- @blacklist

    visited = 
      from(p in __MODULE__, order_by: [desc: p.count], select: p.slug )
      |> YasushisakaiCom.Repo.all()
      |> Enum.map(&String.to_atom/1)
      |> Enum.filter(&(&1 in all))

    visited ++ (all -- visited)
  end

end
