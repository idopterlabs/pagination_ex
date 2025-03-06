defmodule PaginationEx.HTML do
  @moduledoc """
  HTML helpers for pagination rendering with support for custom templates.
  Default implementation uses Tailwind CSS.

  This module provides functions to generate HTML pagination components for
  Phoenix applications. It supports:

  - Standard pagination with next/previous links
  - Numbered page links
  - Customization through template modules
  - Internationalization through Gettext
  - Tailwind CSS styling by default

  The pagination component is designed to work with data already paginated using
  `PaginationEx.Core` and stored in `conn.assigns.pagination`.
  """

  use PhoenixHTMLHelpers

  @doc """
  Renders pagination controls for the current page.

  This function generates HTML pagination controls for the current page. It uses
  the pagination data stored in `conn.assigns.pagination`.

  ## Parameters
    * `conn` - The connection struct containing pagination data in `conn.assigns.pagination`
    * `path` - Either a router helper function name (atom) or a URL string
    * `opts` - Options for customization (optional)
      * `:template_module` - A module that implements `render_pagination/3` for custom rendering

  ## Returns
    * HTML markup for pagination controls or `nil` if total entries is less than per_page

  ## Examples
      # Using a path helper
      <%= PaginationEx.HTML.paginate(@conn, :post_path) %>

      # Using a URL string
      <%= PaginationEx.HTML.paginate(@conn, "/posts") %>

      # Using a custom template
      <%= PaginationEx.HTML.paginate(@conn, :post_path, template_module: MyApp.PaginationTemplate) %>
  """
  @spec paginate(Plug.Conn.t(), atom() | String.t(), keyword()) :: Phoenix.HTML.safe() | nil
  def paginate(conn, path, opts \\ []) do
    template_module = Keyword.get(opts, :template_module)

    if template_module do
      template_module.render_pagination(conn, path, conn.assigns.pagination)
    else
      do_paginate(conn, path, conn.assigns.pagination)
    end
  end

  defp do_paginate(_conn, _path, %{total_entries: total_entries, per_page: per_page})
       when total_entries < per_page,
       do: nil

  defp do_paginate(conn, path, %{
         page_number: current_page,
         pages: pages
       }) do
    previous = previous_path(conn, path, current_page)
    next = next_path(conn, path, current_page, pages)

    pagination =
      content_tag(:p, "#{translate("Pages")}: #{current_page} #{translate("of")} #{pages}",
        class: "text-sm text-gray-700"
      )

    content_tag(
      :nav,
      [pagination, previous, next, content_tag(:ul, [], class: "inline-flex -space-x-px")],
      class: "flex items-center justify-between border-t border-gray-200 px-4 py-3 sm:px-6",
      role: "navigation",
      "aria-label": "pagination"
    )
  end

  @doc """
  Generates HTML for the "Next" pagination link.

  Creates either an active link to the next page or a disabled button if
  the current page is the last page.

  ## Parameters
    * `conn` - The connection struct
    * `path` - Either a router helper function name (atom) or a URL string
    * `current_page` - The current page number
    * `total_pages` - The total number of pages

  ## Returns
    * HTML markup for the next page link

  ## Examples
      <%= PaginationEx.HTML.next_path(@conn, :post_path, 1, 5) %>
  """
  @spec next_path(Plug.Conn.t(), atom() | String.t(), integer(), integer()) :: Phoenix.HTML.safe()
  def next_path(conn, path, current_page, total_pages) do
    if total_pages > current_page do
      next_path_internal(conn, path, current_page)
    else
      content_tag(:a, translate("Next"),
        class:
          "relative inline-flex items-center px-4 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-r-lg cursor-not-allowed",
        disabled: true
      )
    end
  end

  defp next_path_internal(conn, path, ""), do: next_path_internal(conn, path, 1)
  defp next_path_internal(conn, path, nil), do: next_path_internal(conn, path, 1)

  defp next_path_internal(conn, path, page) do
    next_page = page + 1
    url = build_url(conn, path, next_page)

    link(translate("Next"),
      to: url,
      class:
        "relative inline-flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-r-lg hover:bg-gray-50"
    )
  end

  @doc """
  Generates HTML for the "Previous" pagination link.

  Creates either an active link to the previous page or a disabled button if
  the current page is the first page.

  ## Parameters
    * `conn` - The connection struct
    * `path` - Either a router helper function name (atom) or a URL string
    * `current_page` - The current page number

  ## Returns
    * HTML markup for the previous page link

  ## Examples
      <%= PaginationEx.HTML.previous_path(@conn, :post_path, 2) %>
  """
  @spec previous_path(Plug.Conn.t(), atom() | String.t(), integer()) :: Phoenix.HTML.safe()
  def previous_path(conn, path, current_page) do
    if current_page > 1 do
      previous_path_internal(conn, path, current_page)
    else
      content_tag(:a, translate("Previous"),
        class:
          "relative inline-flex items-center px-4 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-l-lg cursor-not-allowed",
        disabled: true
      )
    end
  end

  defp previous_path_internal(conn, path, ""), do: previous_path_internal(conn, path, 1)
  defp previous_path_internal(conn, path, nil), do: previous_path_internal(conn, path, 1)

  defp previous_path_internal(conn, path, page) do
    previous_page = page - 1
    url = build_url(conn, path, previous_page)

    link(translate("Previous"),
      to: url,
      class:
        "relative inline-flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-l-lg hover:bg-gray-50"
    )
  end

  @doc """
  Generates HTML for numbered page links.

  Creates a list of links for all pages, with the current page highlighted.

  ## Parameters
    * `conn` - The connection struct
    * `path` - Either a router helper function name (atom) or a URL string
    * `pagination` - A map containing `:page_number` (current page) and `:pages` (total pages)

  ## Returns
    * List of HTML markup for page links with interspersed spaces

  ## Examples
      <%= for link <- PaginationEx.HTML.page_links(@conn, :post_path, %{page_number: 2, pages: 5}) do %>
        <%= link %>
      <% end %>
  """
  @spec page_links(Plug.Conn.t(), atom() | String.t(), map()) :: list(Phoenix.HTML.safe())
  def page_links(conn, path, %{page_number: current_page, pages: total_pages}) do
    1..total_pages
    |> Enum.map(fn page ->
      page_link(conn, path, page, page == current_page)
    end)
    |> Enum.intersperse(" ")
  end

  defp page_link(conn, path, page, is_current) do
    url = build_url(conn, path, page)

    if is_current do
      content_tag(:span, page,
        class:
          "relative inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-blue-600"
      )
    else
      link(page,
        to: url,
        class:
          "relative inline-flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 hover:bg-gray-50"
      )
    end
  end

  @doc """
  Builds a URL for pagination links.

  This function handles both router helper functions (atoms) and URL strings, creating
  a properly formatted link with the page parameter.

  ## Parameters
    * `conn` - The connection struct
    * `path` - Either a router helper function name (atom) or a URL string
    * `page` - The page number to link to

  ## Returns
    * URL string with page parameter

  ## Examples
      iex> PaginationEx.HTML.build_url(conn, :post_path, 2)
      "/posts?page=2"

      iex> PaginationEx.HTML.build_url(conn, "/posts", 2)
      "/posts?page=2"

      iex> PaginationEx.HTML.build_url(conn, "/posts?sort=asc", 2)
      "/posts?sort=asc&page=2"
  """
  @spec build_url(Plug.Conn.t(), atom() | String.t(), integer()) :: String.t()
  def build_url(conn, path, page) when is_atom(path) do
    router_module = config(:router_helpers) || raise "Router helpers module not configured"
    apply(router_module, path, [conn, :index, Map.put(conn.params, "page", page)])
  end

  def build_url(conn, path, page) do
    params = URI.encode_query(Map.put(conn.params, "page", page))

    if Regex.match?(~r/\?/, path) do
      path <> "&" <> params
    else
      path <> "?" <> params
    end
  end

  @doc """
  Translates text using the configured Gettext module.

  If a Gettext module is configured, the text is passed through gettext for translation.
  Otherwise, the original text is returned unchanged.

  ## Parameters
    * `text` - The text to translate

  ## Returns
    * Translated text if a Gettext module is configured, otherwise the original text

  ## Examples
      iex> PaginationEx.HTML.translate("Next")
      "Next"

      # With configured Gettext module:
      iex> PaginationEx.HTML.translate("Next")
      "Próximo"  # If the locale is set to Portuguese
  """
  @spec translate(String.t()) :: String.t()
  def translate(text) do
    case config(:gettext_module) do
      nil -> text
      module -> module.gettext(text)
    end
  end

  defp config(key) do
    Application.get_env(:pagination_ex, key)
  end
end
