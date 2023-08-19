defmodule Chroma do
  @moduledoc """
  Documentation for `Chroma` client.
  """

  @spec api_url :: String.t()
  def api_url, do: "#{host()}/#{api_base()}/#{api_version()}"

  @spec host :: String.t()
  def host do
    case Application.fetch_env(:chroma, :host) do
      {:ok, host} -> host
      _ -> "http://localhost:8000"
    end
  end

  @spec api_base :: String.t()
  def api_base do
    case Application.fetch_env(:chroma, :api_base) do
      {:ok, api_base} -> api_base
      _ -> "api"
    end
  end

  @spec api_version :: String.t()
  def api_version do
    case Application.fetch_env(:chroma, :api_version) do
      {:ok, api_version} -> api_version
      _ -> "v1"
    end
  end

  @spec username :: String.t()
  def username, do: Application.fetch_env!(:chroma, :username)

  @spec password :: String.t()
  def password, do: Application.fetch_env!(:chroma, :password)
end
