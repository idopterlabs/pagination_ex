defmodule PaginationEx.HTML do
  @moduledoc """
  HTML helpers for pagination rendering with support for custom templates.
  Default implementation uses Tailwind CSS.
  """

  use PhoenixHTMLHelpers

  def paginate(conn, path, opts \\ []) do
    template_module = Keyword.get(opts, :template_module)

    if template_module do
      apply(template_module, :render_pagination, [conn, path, conn.assigns.pagination])
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

  def translate(text) do
    case config(:gettext_module) do
      nil -> text
      module -> apply(module, :gettext, [text])
    end
  end

  defp config(key) do
    Application.get_env(:pagination_ex, key)
  end
end
