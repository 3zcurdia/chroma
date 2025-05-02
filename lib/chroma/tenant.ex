defmodule Chroma.Tenant do
  alias Chroma

  @moduledoc """
  Provides functions to interact with ChromaDB tenants. 
  """
  defstruct [:name]

  @type t :: %__MODULE__{
          name: String.t()
        }
  @doc """
  Creates a new tenant in ChromaDB.

  ## Parameters
  - `name`: The name of the tenant to be created.
  ## Returns
  - `{:ok, tenant}`: If the tenant is created successfully.
  - `{:error, reason}`: If there is an error creating the tenant.
  ## Examples
      iex> Chroma.Tenant.create("my_tenant")
      {:ok, %{}}

      iex> Chroma.Tenant.create(123)
      {:error, "Tenant name must be a string; received: 123"}

      iex> Chroma.Tenant.create("my_tenant")
      {:error, "Unauthorized: Invalid API key"}
  """

  @spec create(String.t()) :: {:ok, %{}} | {:error, String.t()}
  def create(name) when is_binary(name) do
    url = "#{Chroma.api_url()}/tenants/"
    json = %{name: name}

    Req.post(url, json: json)
    |> handle_response()
  end

  def create(name), do: {:error, "Tenant name must be a string; received: #{inspect(name)}"}

  ###### PRIVATE FUNCTIONS ######

  defp handle_response({:ok, %Req.Response{status: status, body: body}})
       when status in 200..299 do
    {:ok, body}
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}})
       when status == 401 do
    {:error, "Unauthorized: #{inspect(body)}"}
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}})
       when status > 499 do
    {:error, "Server error: #{inspect(body)}"}
  end
end
