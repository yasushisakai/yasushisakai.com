defmodule YasushisakaiComWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use YasushisakaiComWeb, :html

  embed_templates "page_html/*"

  def filter_without(all, any, none, q, key, tag) do
    all = if key == :all, do: List.delete(all, tag), else: all
    any = if key == :any, do: List.delete(any, tag), else: any
    none = if key == :none, do: List.delete(none, tag), else: none

    []
    |> maybe_add(:all, all)
    |> maybe_add(:any, any)
    |> maybe_add(:none, none)
    |> maybe_add_q(q)
  end

  defp maybe_add(acc, _key, []), do: acc
  defp maybe_add(acc, key, list), do: acc ++ [{key, Enum.join(list, ",")}]

  defp maybe_add_q(acc, ""), do: acc
  defp maybe_add_q(acc, nil), do: acc
  defp maybe_add_q(acc, q), do: acc ++ [{:q, q}]
end
