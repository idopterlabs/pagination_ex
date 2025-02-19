defmodule PaginationEx.Config do
  @moduledoc """
  Configuration module for PaginationEx.
  """

  @default_per_page 30
  @default_per_group 1000

  @doc """
  Get configuration value with fallback to default.
  """
  def get(key, default \\ nil) do
    Application.get_env(:pagination_ex, key, default)
  end

  @doc """
  Get per page configuration.
  """
  def per_page do
    get(:per_page, @default_per_page)
  end

  @doc """
  Get per group configuration.
  """
  def per_group do
    get(:per_group, @default_per_group)
  end

  @doc """
  Get repo configuration.
  """
  def repo do
    get(:repo) ||
      raise """
      You must configure a repo for PaginationEx. For example:

        config :pagination_ex, :repo, MyApp.Repo
      """
  end

  @doc """
  Get gettext module configuration.
  """
  def gettext_module do
    get(:gettext_module)
  end

  @doc """
  Get router helpers module configuration.
  """
  def router_helpers do
    get(:router_helpers)
  end
end
