defmodule Chroma.Util do
  @moduledoc """
  Basic operations to intereact with the database.
  """

  @doc """
  Resets the database to its initial state.
  """
  @spec reset :: {:ok, map()} | {:error, any}
  def reset, do: Req.post(Chroma.api_url() <> "/reset") |> handle_response()

  @doc """
  Returns the current authenticated user's identity.
  """
  @spec auth_identity :: {:ok, map()} | {:error, any}
  def auth_identity, do: Req.get(Chroma.api_url() <> "/auth/identity") |> handle_response()

  @doc """
  Returns the current state of the database.
  """
  @spec heartbeat :: {:ok, map()} | {:error, any}
  def heartbeat, do: Req.get(Chroma.api_url() <> "/heartbeat") |> handle_response()

  @doc """
  Health check endpoint that returns 200 if the server and executor are ready
  """
  @spec healthcheck :: {:ok, map()} | {:error, any}
  def healthcheck, do: Req.get(Chroma.api_url() <> "/healthcheck") |> handle_response()

  @doc """
  Pre-flight checks endpoint reporting basic readiness info.
  """
  @spec preflight :: {:ok, map()} | {:error, any}
  def preflight, do: Req.get(Chroma.api_url() <> "/pre-flight-checks") |> handle_response()

  @doc """
  Returns the version of the server.
  """
  @spec version :: {:ok, String.t()} | {:error, any}
  def version, do: Req.get(Chroma.api_url() <> "/version") |> handle_response()

  defp handle_response({:ok, %Req.Response{status: status, body: body}}) do
    case status do
      code when code in 200..299 -> {:ok, body}
      _ -> {:error, body}
    end
  end

  defp handle_response(any), do: any
end
