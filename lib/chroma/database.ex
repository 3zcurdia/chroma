defmodule Chroma.Database do
  @moduledoc """
  Documentation for `Chroma.Database`
  """
  @spec version :: String.t()
  def version, do: Req.get!(Chroma.api_url() <> "/version").body

  @spec reset :: Map.t()
  def reset, do: Req.post(Chroma.api_url() <> "/reset") |> handle_response()

  @spec persist :: Map.t()
  def persist, do: Req.post(Chroma.api_url() <> "/persist") |> handle_response()

  @spec heartbeat :: Map.t()
  def heartbeat, do: Req.get(Chroma.api_url() <> "/heartbeat") |> handle_response()

  defp handle_response({:ok, %Req.Response{status: status, body: body}}) do
    case status do
      code when code in 200..299 -> {:ok, body}
      _ -> {:error, body["error"]}
    end
  end

  defp handle_response(any), do: any
end
