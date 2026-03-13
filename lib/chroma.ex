defmodule Chroma do
  @moduledoc """
  A ChromaDB client for Elixir
  """

  @doc """
  It returns the API URL from the configuration.
  """
  @spec api_url :: String.t()
  def api_url, do: "#{host()}/#{api_base()}/#{api_version()}"

  @doc """
  It returns the host from the configuration., or the default value (http://localhost:3000).
  """
  @spec host :: String.t()
  def host do
    case Application.fetch_env(:chroma, :host) do
      {:ok, host} -> host
      _ -> "http://localhost:8000"
    end
  end

  @doc """
  It returns the API base from the configuration., or the default value (api).
  """
  @spec api_base :: String.t()
  def api_base do
    case Application.fetch_env(:chroma, :api_base) do
      {:ok, api_base} -> api_base
      _ -> "api"
    end
  end

  @doc """
  It returns the API version from the configuration., or the default value (v1).
  """
  @spec api_version :: String.t()
  def api_version do
    case Application.fetch_env(:chroma, :api_version) do
      {:ok, api_version} -> api_version
      _ -> "v2"
    end
  end
end
