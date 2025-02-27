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
          page_number: pos_integer(),
          per_page: pos_integer(),
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
    page_number = params |> Map.get("page", 1) |> to_int(:page)
    per_page = params |> Map.get("per_page", @default_per_page) |> to_int(:per_page)
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

  defp entries(query, page_number, per_page, opts)
       when is_integer(page_number) and is_integer(per_page) and per_page > 0 do
    page = max(1, page_number)
    offset = max(0, per_page * (page - 1))

    from(query, offset: ^offset, limit: ^per_page)
    |> repo().all(opts)
  end

  defp entries(_query, _page_number, _per_page, _opts), do: []

  defp total_entries(query, %{"total" => nil}), do: total_entries(query, %{})

  defp total_entries(_query, %{"total" => total}) when is_binary(total) do
    case Integer.parse(total) do
      {num, _} when num >= 0 -> num
      _ -> 0
    end
  end

  defp total_entries(_query, %{"total" => total}) when is_integer(total) and total >= 0, do: total

  defp total_entries(query, _params) do
    cond do
      is_simple_count_query?(query) ->
        query
        |> exclude(:order_by)
        |> exclude(:preload)
        |> exclude(:select)
        |> select([x], count(x.id))
        |> repo().one() || 0

      has_group_by?(query) || has_distinct?(query) ->
        count_query = """
        WITH count_query AS (
          #{query |> exclude(:order_by) |> exclude(:preload) |> exclude(:limit) |> exclude(:offset) |> to_sql()}
        )
        SELECT count(*) FROM count_query
        """

        %{rows: [[count]]} = repo().query!(count_query)
        count || 0

      true ->
        query
        |> exclude(:order_by)
        |> exclude(:preload)
        |> exclude(:select)
        |> exclude(:limit)
        |> exclude(:offset)
        |> subquery()
        |> select([s], count(s))
        |> repo().one() || 0
    end
  end

  defp is_simple_count_query?(query) do
    !has_group_by?(query) && !has_distinct?(query) && !has_joins?(query, [:left, :right, :full])
  end

  defp has_group_by?(%{group_bys: group_bys}) when is_list(group_bys) and length(group_bys) > 0 do
    true
  end

  defp has_group_by?(_), do: false

  defp has_distinct?(%{distinct: %{expr: expr}}) when not is_nil(expr), do: true
  defp has_distinct?(_), do: false

  defp has_joins?(query, types) do
    Enum.any?(query.joins, fn
      %{qual: qual} -> qual in types
      _ -> false
    end)
  end

  defp to_sql(query) do
    {sql, _} = Ecto.Adapters.SQL.to_sql(:all, repo(), query)
    sql
  end

  defp total_pages(total, per_page) when is_integer(per_page) and per_page > 0 do
    Float.ceil(total / per_page) |> Kernel.trunc()
  end

  defp total_pages(_total, _per_page), do: 0

  defp to_int(nil, :page), do: 1
  defp to_int(i, :page) when is_integer(i), do: max(1, i)

  defp to_int(s, :page) when is_binary(s) do
    case Integer.parse(s) do
      {i, _} -> max(1, i)
      _ -> 1
    end
  end

  defp to_int(_, :page), do: 1

  defp to_int(nil, :per_page), do: @default_per_page
  defp to_int(i, :per_page) when is_integer(i) and i > 0, do: i

  defp to_int(s, :per_page) when is_binary(s) do
    case Integer.parse(s) do
      {i, _} when i > 0 -> i
      _ -> @default_per_page
    end
  end

  defp to_int(_, :per_page), do: @default_per_page

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
