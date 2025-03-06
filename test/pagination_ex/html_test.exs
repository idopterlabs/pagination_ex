defmodule PaginationEx.HTMLTest do
  use ExUnit.Case

  alias Phoenix.HTML.Safe

  setup do
    conn = %{
      params: %{},
      assigns: %{
        pagination: %PaginationEx.Core{
          entries: [1, 2, 3],
          total_entries: 10,
          page_number: 2,
          per_page: 3,
          pages: 4
        }
      }
    }

    {:ok, conn: conn}
  end

  describe "paginate/3 with default template" do
    test "renders basic pagination", %{conn: conn} do
      result =
        conn
        |> PaginationEx.paginate("/test")
        |> Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert result =~ "Pages: 2 of 4"
      assert result =~ "Previous"
      assert result =~ "Next"
    end

    test "handles paths with existing query params", %{conn: conn} do
      conn = %{conn | params: %{"filter" => "active"}}

      result =
        conn
        |> PaginationEx.paginate("/test?sort=desc")
        |> Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert result =~ "sort=desc"
      assert result =~ "page="
    end

    test "disables previous on first page", %{conn: conn} do
      conn = put_in(conn.assigns.pagination.page_number, 1)

      result =
        conn
        |> PaginationEx.paginate("/test")
        |> Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert result =~ "disabled"
      assert result =~ "cursor-not-allowed"
      assert result =~ "Previous"
      refute result =~ "href=\"/test?page=0\""
    end

    test "disables next on last page", %{conn: conn} do
      conn = put_in(conn.assigns.pagination.page_number, 4)

      result =
        conn
        |> PaginationEx.paginate("/test")
        |> Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert result =~ "disabled"
      assert result =~ "cursor-not-allowed"
      assert result =~ "Next"
      refute result =~ "href=\"/test?page=5\""
    end

    test "includes proper ARIA attributes", %{conn: conn} do
      result =
        conn
        |> PaginationEx.paginate("/test")
        |> Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert result =~ ~s(role="navigation")
      assert result =~ ~s(aria-label="pagination")
    end

    test "handles no results", %{conn: conn} do
      conn = put_in(conn.assigns.pagination.total_entries, 0)
      conn = put_in(conn.assigns.pagination.per_page, 10)
      result = PaginationEx.paginate(conn, "/test")
      assert result == nil
    end
  end

  describe "paginate/3 with custom template" do
    defmodule TestTemplateModule do
      use PhoenixHTMLHelpers

      def render_pagination(_conn, _path, %{total_entries: total_entries, per_page: per_page})
          when total_entries < per_page,
          do: nil

      def render_pagination(_conn, _path, %{page_number: current_page, pages: total_pages}) do
        content_tag(
          :div,
          [
            content_tag(:p, "Custom Pages: #{current_page}/#{total_pages}"),
            content_tag(:div, "Custom Pagination")
          ],
          class: "custom-pagination"
        )
      end
    end

    test "uses custom template when provided", %{conn: conn} do
      result =
        conn
        |> PaginationEx.paginate("/test", template_module: TestTemplateModule)
        |> Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert result =~ "Custom Pages: 2/4"
      assert result =~ "Custom Pagination"
      assert result =~ "custom-pagination"
    end

    test "custom template handles no results", %{conn: conn} do
      conn = put_in(conn.assigns.pagination.total_entries, 0)
      conn = put_in(conn.assigns.pagination.per_page, 10)
      result = PaginationEx.paginate(conn, "/test", template_module: TestTemplateModule)
      assert result == nil
    end
  end
end
