defmodule Chroma.Database do
  @moduledoc """
  Documentation for `Chroma.Database`
  """

  @doc """
  Returns the current vesion of the Chroma database.
  """
  @spec version :: String.t()
  def version, do: Req.get!(Chroma.api_url() <> "/version").body

  @doc """
  Resets the database to its initial state.
  """
  @spec reset :: map()
  def reset, do: Req.post(Chroma.api_url() <> "/reset") |> handle_response()

  @doc """
  Persists the database to disk.
  """
  @spec persist :: map()
  def persist, do: Req.post(Chroma.api_url() <> "/persist") |> handle_response()

  @doc """
  Returns the current state of the database.
  """
  @spec heartbeat :: map()
  def heartbeat, do: Req.get(Chroma.api_url() <> "/heartbeat") |> handle_response()

  defp handle_response({:ok, %Req.Response{status: status, body: body}}) do
    case status do
      code when code in 200..299 -> {:ok, body}
      _ -> {:error, body["error"]}
    end
  end

  defp handle_response(any), do: any
end
