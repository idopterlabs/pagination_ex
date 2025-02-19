defmodule PaginationEx do
  @moduledoc """
  PaginationEx provides pagination functionality for Elixir applications.
  """

  alias PaginationEx.Core
  alias PaginationEx.HTML

  @doc """
  Creates a new pagination struct from a query and params.
  """
  defdelegate new(query, params, opts \\ []), to: Core

  @doc """
  Paginates results in groups.
  """
  defdelegate in_groups(query, params \\ %{}), to: Core

  @doc """
  Renders pagination links in HTML.
  """
  defdelegate paginate(conn, path), to: HTML
end
