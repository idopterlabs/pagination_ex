defmodule PaginationEx.CoreTest do
  use ExUnit.Case
  use Ecto.Schema

  import Ecto.Query
  require Logger

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
    original_log_level = Logger.level()
    original_backends = :logger.get_handler_config()

    Logger.configure(level: :error)
    :logger.remove_handler(:default)

    Application.put_env(:pagination_ex, TestRepo,
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      port: 5432,
      database: "pagination_ex_test",
      pool: Ecto.Adapters.SQL.Sandbox,
      log: false
    )

    Application.put_env(:ecto, :logger, false)
    Application.put_env(:postgrex, :debug_logger, false)

    TestRepo.start_link()

    on_exit(fn ->
      Logger.configure(level: original_log_level)

      :logger.add_handler(:default, :logger_std_h, %{
        config: %{type: :standard_io},
        formatter: original_backends[:default][:formatter]
      })
    end)

    :ok
  end

  setup do
    TestRepo.query!("DROP TABLE IF EXISTS test_item_details CASCADE")
    TestRepo.query!("DROP TABLE IF EXISTS test_items CASCADE")

    TestRepo.query!("""
      CREATE TABLE IF NOT EXISTS test_items (
        id serial primary key,
        name text,
        category text,
        inserted_at timestamp without time zone DEFAULT current_timestamp,
        updated_at timestamp without time zone DEFAULT current_timestamp
      )
    """)

    TestRepo.query!("""
      CREATE TABLE IF NOT EXISTS test_item_details (
        id serial primary key,
        item_id integer references test_items(id),
        details text,
        tag text
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

    test "successfully paginates with GROUP BY query" do
      query =
        from(i in TestSchema,
          group_by: i.category,
          select: {i.category, count(i.id)}
        )

      result = PaginationEx.new(query, %{})

      assert result.page_number == 1
      assert result.total_entries == 4
      assert result.pages == 1
      assert length(result.entries) == 4
    end

    test "paginates GROUP BY query with custom page and per_page" do
      query =
        from(i in TestSchema,
          group_by: i.category,
          select: {i.category, count(i.id)}
        )

      result = PaginationEx.new(query, %{"page" => "1", "per_page" => "2"})

      assert result.page_number == 1
      assert result.per_page == 2
      assert result.total_entries == 4
      assert result.pages == 2
      assert length(result.entries) == 2
    end

    test "handles empty result set with GROUP BY" do
      query =
        from(i in TestSchema,
          where: i.name == "NonExistent",
          group_by: i.category,
          select: {i.category, count(i.id)}
        )

      result = PaginationEx.new(query, %{})

      assert result.page_number == 1
      assert result.total_entries == 0
      assert result.pages == 0
      assert length(result.entries) == 0
    end

    test "successfully paginates with GROUP BY and ORDER BY" do
      query =
        from(i in TestSchema,
          group_by: i.category,
          order_by: [desc: count(i.id)],
          select: {i.category, count(i.id)}
        )

      result = PaginationEx.new(query, %{})

      assert result.page_number == 1
      assert result.total_entries == 4
      assert result.pages == 1
      assert length(result.entries) == 4
    end

    test "handles complex GROUP BY with multiple grouping expressions" do
      for i <- 1..10 do
        TestRepo.query!(
          "INSERT INTO test_items (name, category) VALUES ($1, $2)",
          ["Extra Item #{i}", "Extra Category"]
        )
      end

      query =
        from(i in TestSchema,
          group_by: [i.category, fragment("date_trunc('day', ?)", i.inserted_at)],
          select: {i.category, fragment("date_trunc('day', ?)", i.inserted_at), count(i.id)}
        )

      result = PaginationEx.new(query, %{})

      assert result.total_entries == 5
      assert length(result.entries) == 5
    end

    test "handles DISTINCT queries" do
      for _ <- 1..5 do
        TestRepo.query!(
          "INSERT INTO test_items (name, category) VALUES ($1, $2)",
          ["Duplicate Item", "Duplicate Category"]
        )
      end

      query =
        from(i in TestSchema,
          distinct: i.category,
          select: i.category
        )

      result = PaginationEx.new(query, %{})

      assert result.total_entries == 5
      assert length(result.entries) == 5
    end

    test "handles queries with JOIN" do
      for i <- 1..10 do
        TestRepo.query!(
          "INSERT INTO test_item_details (item_id, details) VALUES ($1, $2)",
          [i, "Details for item #{i}"]
        )
      end

      query =
        from(i in TestSchema,
          join: d in "test_item_details",
          on: i.id == d.item_id,
          select: {i.id, i.name, d.details}
        )

      result = PaginationEx.new(query, %{})

      assert result.total_entries == 10
      assert length(result.entries) == 10
    end

    test "handles queries with JOIN and GROUP BY" do
      for i <- 1..10 do
        tag = (rem(i, 3) == 0 && "tag_a") || "tag_b"

        TestRepo.query!(
          "INSERT INTO test_item_details (item_id, details, tag) VALUES ($1, $2, $3)",
          [i, "Details for item #{i}", tag]
        )
      end

      query =
        from(i in TestSchema,
          join: d in "test_item_details",
          on: i.id == d.item_id,
          group_by: d.tag,
          select: {d.tag, count(i.id)}
        )

      result = PaginationEx.new(query, %{})

      assert result.total_entries == 2
      assert length(result.entries) == 2
    end

    test "performance of count with large dataset" do
      TestRepo.query!("TRUNCATE test_items RESTART IDENTITY CASCADE")

      batch_size = 100
      total_records = 1000

      for batch <- 0..div(total_records - 1, batch_size) do
        params =
          for i <- 1..batch_size do
            index = batch * batch_size + i
            category = "Category #{div(index, 100)}"
            ["Item #{index}", category]
          end

        placeholders =
          params
          |> Enum.with_index()
          |> Enum.map(fn {_, idx} -> "($#{idx * 2 + 1}, $#{idx * 2 + 2})" end)
          |> Enum.join(", ")

        values = params |> List.flatten()

        TestRepo.query!(
          "INSERT INTO test_items (name, category) VALUES " <> placeholders,
          values
        )
      end

      {time_normal, result_normal} =
        :timer.tc(fn ->
          query = from(i in TestSchema)
          PaginationEx.new(query, %{})
        end)

      {time_group, result_group} =
        :timer.tc(fn ->
          query =
            from(i in TestSchema,
              group_by: i.category,
              select: {i.category, count(i.id)}
            )

          PaginationEx.new(query, %{})
        end)

      assert result_normal.total_entries == total_records
      assert result_group.total_entries >= 10 && result_group.total_entries <= 11

      assert time_group < time_normal * 10, "GROUP BY query time should not be excessive"
    end
  end
end
