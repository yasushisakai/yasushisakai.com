defmodule YasushisakaiCom.Pages do
  alias YasushisakaiCom.Markdown

  def all_tags do
    Markdown.all_names()
    |> Enum.flat_map(&Markdown.tags/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def tag_counts do
    Markdown.all_names()
    |> Enum.flat_map(&Markdown.tags/1)
    |> Enum.frequencies()
  end

  def filter(opts \\ []) do
    all =   Keyword.get(opts, :all, [])
    any =   Keyword.get(opts, :any, [])
    none =  Keyword.get(opts, :none, [])

    Markdown.all_names()
    |> Enum.filter(fn name -> 
      tags = Markdown.tags(name)
      matches_all?(tags, all) and matches_any?(tags, any) and matches_none?(tags, none)
    end)
  end

  defp matches_all?(_tags, []), do: true
  defp matches_all?(tags, required), do: Enum.all?(required, &(&1 in tags)) 

  defp matches_any?(_tags, []), do: true
  defp matches_any?(tags, optional), do: Enum.any?(optional, &(&1 in tags))

  defp matches_none?(_tags, []), do: true
  defp matches_none?(tags, excluded), do: Enum.all?(excluded, &(&1 not in tags))
end
