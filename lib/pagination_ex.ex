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
  defdelegate paginate(conn, path, opts \\ []), to: HTML

  @doc """
  Generates the "Next" link or disabled button based on the current page and total pages.
  Useful for custom pagination templates.
  """
  defdelegate next_path(conn, path, current_page, total_pages), to: HTML

  @doc """
  Generates the "Previous" link or disabled button based on the current page.
  Useful for custom pagination templates.
  """
  defdelegate previous_path(conn, path, current_page), to: HTML

  @doc """
  Generates numeric links for each page.
  Useful for custom pagination templates.
  """
  defdelegate page_links(conn, path, pagination), to: HTML

  @doc """
  Builds the URL for a specific page.
  Useful for custom pagination templates.
  """
  defdelegate build_url(conn, path, page), to: HTML

  @doc """
  Translates text using configured Gettext module if available.
  Useful for custom pagination templates.
  """
  defdelegate translate(text), to: HTML
end
