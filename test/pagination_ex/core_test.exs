defmodule PaginationEx.CoreTest do
  use ExUnit.Case
  use Ecto.Schema

  import Ecto.Query

  @default_per_page 30

  defmodule TestRepo do
    use Ecto.Repo,
      otp_app: :pagination_ex,
      adapter: Ecto.Adapters.Postgres
  end

  defmodule TestSchema do
    use Ecto.Schema

    schema "test_items" do
      field(:name, :string)
      field(:category, :string)
      timestamps()
    end
  end

  setup_all do
    Application.put_env(:pagination_ex, TestRepo,
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      port: 5432,
      database: "pagination_ex_test",
      pool: Ecto.Adapters.SQL.Sandbox
    )

    TestRepo.start_link()

    :ok
  end

  setup do
    TestRepo.query!("DROP TABLE IF EXISTS test_items")

    TestRepo.query!("""
      CREATE TABLE IF NOT EXISTS test_items (
        id serial primary key,
        name text,
        category text,
        inserted_at timestamp without time zone DEFAULT current_timestamp,
        updated_at timestamp without time zone DEFAULT current_timestamp
      )
    """)

    for i <- 1..30 do
      TestRepo.query!(
        "INSERT INTO test_items (name, category) VALUES ($1, $2)",
        ["Item #{i}", "Category #{div(i, 10)}"]
      )
    end

    Application.put_env(:pagination_ex, :repo, TestRepo)

    :ok
  end

  describe "pagination" do
    test "successfully paginates with default params" do
      query = from(i in TestSchema)
      result = PaginationEx.new(query, %{})

      assert result.page_number == 1
      assert result.per_page == 30
      assert result.total_entries == 30
      assert result.pages == 1
      assert length(result.entries) == 30
    end

    test "successfully paginates with custom page and per_page" do
      query = from(i in TestSchema)
      result = PaginationEx.new(query, %{"page" => "2", "per_page" => "10"})

      assert result.page_number == 2
      assert result.per_page == 10
      assert result.total_entries == 30
      assert result.pages == 3
      assert length(result.entries) == 10
    end

    test "handles empty result set" do
      query = from(i in TestSchema, where: i.name == "NonExistent")
      result = PaginationEx.new(query, %{})

      assert result.page_number == 1
      assert result.total_entries == 0
      assert result.pages == 0
      assert length(result.entries) == 0
    end

    test "in_groups returns all items" do
      query = from(i in TestSchema)
      result = PaginationEx.in_groups(query, %{"per_group" => "10"})

      assert length(result) == 30
    end

    test "handles invalid page number" do
      query = from(i in TestSchema)
      result = PaginationEx.new(query, %{"page" => "invalid"})

      assert result.page_number == 1
    end

    test "handles zero per_page" do
      query = from(i in TestSchema)
      result = PaginationEx.new(query, %{"per_page" => "0"})

      assert result.per_page == @default_per_page
    end

    test "handles negative per_page" do
      query = from(i in TestSchema)
      result = PaginationEx.new(query, %{"per_page" => "-10"})

      assert result.per_page == @default_per_page
    end

    test "handles page number greater than total pages" do
      query = from(i in TestSchema)
      result = PaginationEx.new(query, %{"page" => "5"})

      assert result.page_number == 5
      assert result.total_entries == 30
      assert length(result.entries) == 0
    end

    test "accepts total override in params" do
      query = from(i in TestSchema)
      result = PaginationEx.new(query, %{"total" => "50"})

      assert result.total_entries == 50
    end

    test "handles nil values in params" do
      query = from(i in TestSchema)
      result = PaginationEx.new(query, %{"page" => nil, "per_page" => nil})

      assert result.page_number == 1
      assert result.per_page == 30
    end

    test "handles missing repo configuration" do
      Application.delete_env(:pagination_ex, :repo)

      assert_raise RuntimeError, ~r/You must configure a repo/, fn ->
        query = from(i in TestSchema)
        PaginationEx.new(query, %{})
      end
    end

    test "handles in_groups with empty result set" do
      query = from(i in TestSchema, where: i.name == "NonExistent")
      result = PaginationEx.in_groups(query, %{})

      assert length(result) == 0
    end

    test "accepts integer params" do
      query = from(i in TestSchema)
      result = PaginationEx.new(query, %{"page" => 2, "per_page" => 10})

      assert result.page_number == 2
      assert result.per_page == 10
      assert result.total_entries == 30
    end

    test "calculates total pages correctly with remainder" do
      query = from(i in TestSchema)
      result = PaginationEx.new(query, %{"per_page" => "7"})

      assert result.pages == 5
    end

    test "keeps original query in struct" do
      query = from(i in TestSchema)
      result = PaginationEx.new(query, %{})

      assert result.query == query
    end

    test "handles very large page numbers" do
      query = from(i in TestSchema)
      result = PaginationEx.new(query, %{"page" => "999999"})

      assert result.page_number == 999_999
      assert length(result.entries) == 0
    end

    test "handles very large per_page" do
      query = from(i in TestSchema)
      result = PaginationEx.new(query, %{"per_page" => "999999"})

      assert result.per_page == 999_999
      assert length(result.entries) == 30
    end
  end
end
