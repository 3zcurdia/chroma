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
  Creates a new tenant struct.
  ## Parameters
  - `attrs`: A map containing the attributes for the tenant.
  ## Returns
  - `{:ok, tenant}`: If the tenant is created successfully.
  - `{:error, reason}`: If there is an error creating the tenant.

  ## Examples
      iex> Chroma.Tenant.new(%{"name" => "my_tenant"})
      {:ok, %Chroma.Tenant{name: "my_tenant"}}

      iex> Chroma.Tenant.new(%{"name" => 123})
      {:error, "Invalid input for Chroma.Tenant: %{name: 123}"}
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}

  def new(%{"name" => name}), do: {:ok, %Chroma.Tenant{name: name}}

  def new(other), do: {:error, "Invalid input for Chroma.Tenant: #{inspect(other)}"}

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
    url = "#{Chroma.api_url()}/tenants"
    json = %{name: name}

    Req.post(url, json: json)
    |> handle_response()
  end

  def create(name), do: {:error, "Tenant name must be a string; received: #{inspect(name)}"}

  @doc """
  Retrieves a tenant from ChromaDB.
  ## Parameters
  - `name`: The name of the tenant to be retrieved.
  ## Returns
  - `{:ok, tenant}`: If the tenant is retrieved successfully.
  - `{:error, reason}`: If there is an error retrieving the tenant.
  ## Examples
      iex> Chroma.Tenant.get("my_tenant")
      {:ok, %Chroma.Tenant{name: "my_tenant"}}

      iex> Chroma.Tenant.get(123)
      {:error, "Tenant name must be a string; received: 123"}

      iex> Chroma.Tenant.get("non_existent_tenant")
      {:error, "Server error: Tenant not found"}
  """
  @spec get(String.t()) :: {:ok, t()} | {:error, String.t()}

  def get(name) when is_binary(name) do
    url = "#{Chroma.api_url()}/tenants/#{name}"

    Req.get(url)
    |> handle_response()
  end

  def get(name), do: {:error, "Tenant name must be a string; received: #{inspect(name)}"}

  ###### PRIVATE FUNCTIONS ######

  defp handle_response({:ok, %Req.Response{status: status, body: body}})
       when status in 200..299 and is_map(body) do
    if map_size(body) == 0 do
      {:ok, %{}}
    else
      case body do
        %{"name" => _name} -> {new(body)}
        _ -> {:error, "Unexpected response format: #{inspect(body)}"}
      end
    end
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}})
       when status == 401 do
    {:error, "Unauthorized: #{inspect(body)}"}
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}})
       when status == 404 do
    {:error, "Not Found: #{inspect(body)}"}
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}})
       when status == 409 do
    {:error, "Conflict: #{inspect(body)}"}
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}})
       when status in 500..599 do
    {:error, "Server error: #{inspect(body)}"}
  end
end
