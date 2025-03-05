defmodule PaginationEx.Config do
  @moduledoc """
  Configuration module for PaginationEx.

  This module provides configuration management for the PaginationEx library.
  It handles retrieval of configuration values from the application environment
  with fallback to default values, and provides access to essential configuration
  options like pagination limits and required dependencies.
  """

  @default_per_page 30
  @default_per_group 1000

  @doc """
  Get configuration value with fallback to default.

  ## Parameters
    * `key` - The configuration key to look up under the `:pagination_ex` application environment
    * `default` - The default value to return if the key is not found

  ## Returns
    * The configured value for the given key, or the provided default if not configured

  ## Examples
      # Assuming configuration:
      # config :pagination_ex, :custom_setting, "custom_value"

      iex> PaginationEx.Config.get(:custom_setting)
      "custom_value"
      iex> PaginationEx.Config.get(:missing_setting)
      nil
      iex> PaginationEx.Config.get(:missing_setting, "default")
      "default"
  """
  @spec get(atom(), term()) :: term()
  def get(key, default \\ nil) do
    Application.get_env(:pagination_ex, key, default)
  end

  @doc """
  Get per page configuration.

  ## Returns
    * The configured `:per_page` value, or `#{@default_per_page}` if not configured

  ## Examples
      # With default configuration
      iex> PaginationEx.Config.per_page()
      30

      # With custom configuration:
      # config :pagination_ex, :per_page, 50
      iex> PaginationEx.Config.per_page()
      50
  """
  @spec per_page() :: non_neg_integer()
  def per_page do
    get(:per_page, @default_per_page)
  end

  @doc """
  Get per group configuration.

  ## Returns
    * The configured `:per_group` value, or `#{@default_per_group}` if not configured

  ## Examples
      # With default configuration
      iex> PaginationEx.Config.per_group()
      1000

      # With custom configuration:
      # config :pagination_ex, :per_group, 500
      iex> PaginationEx.Config.per_group()
      500
  """
  @spec per_group() :: non_neg_integer()
  def per_group do
    get(:per_group, @default_per_group)
  end

  @doc """
  Get repo configuration.

  ## Returns
    * The configured `:repo` module

  ## Raises
    * Runtime error if `:repo` is not configured

  ## Examples
      # With configuration:
      # config :pagination_ex, :repo, MyApp.Repo
      iex> PaginationEx.Config.repo()
      MyApp.Repo

      # Without configuration:
      iex> PaginationEx.Config.repo()
      ** (RuntimeError) You must configure a repo for PaginationEx...
  """
  @spec repo() :: module()
  def repo do
    get(:repo) ||
      raise """
      You must configure a repo for PaginationEx. For example:

        config :pagination_ex, :repo, MyApp.Repo
      """
  end

  @doc """
  Get gettext module configuration.

  ## Returns
    * The configured `:gettext_module`, or `nil` if not configured

  ## Examples
      # With configuration:
      # config :pagination_ex, :gettext_module, MyApp.Gettext
      iex> PaginationEx.Config.gettext_module()
      MyApp.Gettext

      # Without configuration:
      iex> PaginationEx.Config.gettext_module()
      nil
  """
  @spec gettext_module() :: module() | nil
  def gettext_module do
    get(:gettext_module)
  end

  @doc """
  Get router helpers module configuration.

  ## Returns
    * The configured `:router_helpers`, or `nil` if not configured

  ## Examples
      # With configuration:
      # config :pagination_ex, :router_helpers, MyAppWeb.Router.Helpers
      iex> PaginationEx.Config.router_helpers()
      MyAppWeb.Router.Helpers

      # Without configuration:
      iex> PaginationEx.Config.router_helpers()
      nil
  """
  @spec router_helpers() :: module() | nil
  def router_helpers do
    get(:router_helpers)
  end
end
