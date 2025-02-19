defmodule PaginationEx.Core do
  @moduledoc """
  Core pagination functionality.
  """

  import Ecto.Query

  @derive {Jason.Encoder, only: [:entries, :total_entries, :page_number, :per_page, :pages]}
  defstruct [:entries, :total_entries, :page_number, :per_page, :pages, :query]

  @type t() :: %__MODULE__{
          entries: list(any()),
          total_entries: integer(),
          page_number: non_neg_integer(),
          per_page: integer(),
          pages: non_neg_integer(),
          query: Ecto.Query.t()
        }

  @default_per_page 30
  @default_per_group 1000

  def in_groups(query, params \\ %{}) do
    query
    |> new(set_group_params(params))
    |> get_group([])
  end

  def new(query, params, opts \\ []) do
    page_number = params |> Map.get("page", 1) |> to_int()
    per_page = params |> Map.get("per_page", config(:per_page, @default_per_page)) |> to_int()
    total = total_entries(query, params)

    %__MODULE__{
      entries: entries(query, page_number, per_page, opts),
      total_entries: total,
      page_number: page_number,
      per_page: per_page,
      pages: total_pages(total, per_page),
      query: query
    }
  end

  defp entries(query, page_number, per_page, opts) when is_integer(page_number) do
    offset = per_page * (page_number - 1)

    from(query, offset: ^offset, limit: ^per_page)
    |> repo().all(opts)
  end

  defp entries(_query, :error, _per_page, _opts), do: []

  defp total_entries(query, %{"total" => nil}), do: total_entries(query, %{})

  defp total_entries(_query, %{"total" => total}), do: total

  defp total_entries(query, _params) do
    query
    |> repo().aggregate(:count, :id)
  end

  defp total_pages(total, per_page) do
    Float.ceil(total / per_page) |> Kernel.trunc()
  end

  defp to_int(i) when is_integer(i), do: i

  defp to_int(s) when is_binary(s) do
    case Integer.parse(s) do
      {i, _} -> i
      :error -> :error
    end
  end

  defp to_int(_other), do: :error

  defp set_group_params(params) do
    per_group = Map.get(params, "per_group", config(:per_group, @default_per_group))
    total = Map.get(params, "total")

    %{
      "per_page" => per_group,
      "total" => total
    }
  end

  defp get_group(
         %__MODULE__{page_number: page_number, pages: pages} = pagination,
         collection
       )
       when page_number == pages or pages == 0 do
    collection ++ pagination.entries
  end

  defp get_group(
         %__MODULE__{
           page_number: page_number,
           per_page: per_page,
           total_entries: total_entries,
           entries: entries,
           query: query
         },
         collection
       ) do
    query
    |> new(
      %{}
      |> Map.put("total", total_entries)
      |> Map.put("per_page", per_page)
      |> Map.put("page", page_number + 1)
    )
    |> get_group(collection ++ entries)
  end

  defp repo do
    Application.get_env(:pagination_ex, :repo) ||
      raise """
      You must configure a repo for PaginationEx. For example:

        config :pagination_ex, :repo, MyApp.Repo
      """
  end

  defp config(key, default) do
    Application.get_env(:pagination_ex, key, default)
  end
end
