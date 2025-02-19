defmodule PaginationEx.CoreTest do
  use ExUnit.Case
  use Ecto.Schema
  import Ecto.Query

  defmodule TestSchema do
    use Ecto.Schema

    schema "test_items" do
      field(:name, :string)
      field(:category, :string)
      timestamps()
    end
  end

  defmodule TestRepo do
    use Ecto.Repo,
      otp_app: :pagination_ex,
      adapter: Ecto.Adapters.Postgres
  end

  setup do
    Application.put_env(:pagination_ex, TestRepo,
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      port: 5432,
      database: "pagination_ex_test",
      pool: Ecto.Adapters.SQL.Sandbox,
      pool_size: 10
    )

    {:ok, _} = TestRepo.start_link()

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

      assert result.page_number == :error
      assert result.total_entries == 30
    end
  end
end
