defmodule PaginationEx.HTMLTest do
  use ExUnit.Case

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

  describe "paginate/2" do
    test "renders basic pagination", %{conn: conn} do
      result =
        conn
        |> PaginationEx.paginate("/test")
        |> Phoenix.HTML.Safe.to_iodata()
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
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert result =~ "sort=desc"
      assert result =~ "page="
    end

    test "disables previous on first page", %{conn: conn} do
      conn = put_in(conn.assigns.pagination.page_number, 1)

      result =
        conn
        |> PaginationEx.paginate("/test")
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert result =~ ~s(cursor-not-allowed" disabled>Previous)
    end

    test "disables next on last page", %{conn: conn} do
      conn = put_in(conn.assigns.pagination.page_number, 4)

      result =
        conn
        |> PaginationEx.paginate("/test")
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert result =~ ~s(cursor-not-allowed" disabled>Next)
    end

    test "includes proper ARIA attributes", %{conn: conn} do
      result =
        conn
        |> PaginationEx.paginate("/test")
        |> Phoenix.HTML.Safe.to_iodata()
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
end
