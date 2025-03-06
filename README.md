# PaginationEx

A flexible and robust pagination library for Elixir/Phoenix applications that integrates seamlessly with Ecto.

## Features

- **Simple Integration**: Easily paginate Ecto queries with minimal configuration
- **Flexible Rendering**: HTML helpers with Tailwind CSS styling by default
- **Customizable**: Support for custom templates and styling
- **Internationalization**: Built-in i18n support via Gettext
- **Performance Optimized**: Smart counting strategies for different query types

## Installation

The package is not yet available on Hex.pm. To install directly from GitHub, add to your dependencies:

```elixir
def deps do
  [
    {:pagination_ex, "~> 0.1.0"}
  ]
end
```

## Configuration

Configure PaginationEx in your application's config file:

```elixir
# In config/config.exs or environment-specific config files
config :pagination_ex,
  repo: MyApp.Repo,                        # Required
  per_page: 25,                            # Optional, defaults to 30
  per_group: 500,                          # Optional, defaults to 1000
  gettext_module: MyApp.Gettext,           # Optional for internationalization
  router_helpers: MyAppWeb.Router.Helpers  # Optional for route generation
```

## Usage

### Basic Pagination

```elixir
# In your controller
def index(conn, params) do
  pagination = 
    MyApp.Posts
    |> PaginationEx.new(params)
  
  render(conn, "index.html", pagination: pagination)
end
```

### In Templates

```elixir
# In your template
<%= for post <- @pagination.entries do %>
  <div class="post">
    <h2><%= post.title %></h2>
    <p><%= post.content %></p>
  </div>
<% end %>

<div class="pagination">
  <%= PaginationEx.paginate(@conn, :post_path) %>
</div>
```

### Batch Processing with Groups

For processing large datasets in batches:

```elixir
# This fetches all items in batches of the configured size
all_items = PaginationEx.in_groups(MyApp.Items)

# Process all items
Enum.each(all_items, fn item ->
  # Process each item
end)
```

### Custom Templates

Create a custom template module:

```elixir
defmodule MyApp.CustomPaginationTemplate do
  use PhoenixHTMLHelpers
  import PaginationEx.HTML, only: [translate: 1, build_url: 3]
  
  def render_pagination(conn, path, pagination) do
    # Your custom rendering logic here
  end
end
```

Then use it in your templates:

```elixir
<%= PaginationEx.paginate(@conn, :post_path, template_module: MyApp.CustomPaginationTemplate) %>
```

## API Documentation

### PaginationEx.Core

The `Core` module handles the pagination logic and query execution.

Key functions:
- `new/3`: Creates a new pagination struct from an Ecto query
- `in_groups/2`: Retrieves all records in batches of specified size

### PaginationEx.HTML

The `HTML` module renders pagination controls in templates.

Key functions:
- `paginate/3`: Renders complete pagination controls
- `page_links/3`: Generates numbered page links
- `previous_path/3` and `next_path/4`: Creates previous/next navigation links

### PaginationEx.Config

The `Config` module handles configuration retrieval.

## Pagination Structure

The pagination result is a struct with the following fields:

```elixir
%PaginationEx.Core{
  entries: [%Post{}, %Post{}, ...],  # The current page's items
  total_entries: 59,                 # Total number of items
  page_number: 2,                    # Current page number
  per_page: 10,                      # Items per page
  pages: 6,                          # Total number of pages
  query: #Ecto.Query<...>            # The original query
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
6. Wait for the review

And voilà! Your ice cream is ready ✨

## Authors

- **Rômulo Silva (Tomate)** - _Alchemist & Developer_ [Github](https://github.com/rohlacanna)
- **Paulo Igor (Pigor)** - _Alchemist & Developer_ [Github](https://github.com/pigor)
- **Mateus Linhares (Mateus)** - _Alchemist & Developer_ [Github](https://github.com/mateuslinhares)

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.