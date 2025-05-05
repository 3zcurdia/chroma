defmodule Chroma.Database do
  alias Chroma

  @moduledoc """
  Provides functions to interact with ChromaDB tenant databases. 
  """
  defstruct [:id, :name, :tenant]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          tenant: String.t()
        }

  @doc """
  Creates a new database struct.
  ## Parameters
  - `attrs`: A map containing the attributes for the database.
  ## Returns
  - `{:ok, database}`: If the database is created successfully.
  - `{:error, reason}`: If there is an error creating the database.
  ## Examples
      iex> Chroma.Database.new(%{"id" => "db1", "name" => "my_database", "tenant" => "my_tenant"})
      {:ok, %Chroma.Database{id: "db1", name: "my_database", tenant: "my_tenant"}}

      iex> Chroma.Database.new(%{"id" => 123})
      {:error, "Invalid input for Chroma.Database: %{id: 123}"}
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}

  def new(%{"id" => id, "name" => name, "tenant" => tenant}),
    do: {:ok, %Chroma.Database{id: id, name: name, tenant: tenant}}

  def new(other), do: {:error, "Invalid input for Chroma.Tenant: #{inspect(other)}"}

  @doc """
  Creates a new database in ChromaDB.
  ## Parameters
  - `name`: The name of the database to be created.
  - `tenant`: The tenant to which the database belongs.
  ## Returns
  - `{:ok, %{}}`: If the database is created successfully.
  - `{:error, reason}`: If there is an error creating the database.
  ## Examples
      iex> Chroma.Database.create("my_database", "my_tenant")
      {:ok, %{}}

      iex> Chroma.Database.create(123, "my_tenant")
      {:error, "Database name and tenant must be strings, and greater than 2 characters; received: 123, \"my_tenant\""}

      iex> Chroma.Database.create("my_database", "my_tenant")
      {:error, "Unauthorized: Invalid API key"}
  """
  @spec create(String.t(), String.t()) :: {:ok, %{}} | {:error, String.t()}

  def create(name, tenant)
      when is_binary(name) and byte_size(name) > 2 and
             is_binary(tenant) and byte_size(tenant) > 2 do
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases"
    json = %{name: name, tenant: tenant}

    Req.post(url, json: json)
    |> handle_response()
  end

  def create(name, tenant) do
    {:error,
     "Database name and tenant must be strings, and greater than 2 characters; received: #{inspect(name)}, #{inspect(tenant)}"}
  end

  @doc """
  Retrieves a database from ChromaDB.
  ## Parameters
  - `name`: The name of the database to be retrieved.
  - `tenant`: The tenant to which the database belongs.
  ## Returns
  - `{:ok, database}`: If the database is retrieved successfully.
  - `{:error, reason}`: If there is an error retrieving the database.
  ## Examples
      iex> Chroma.Database.get("my_database", "my_tenant")
      {:ok, %Chroma.Database{id: "db1", name: "my_database", tenant: "my_tenant"}}

      iex> Chroma.Database.get(123, "my_tenant")
      {:error, "Database name and tenant must be strings, and greater than 2 characters; received: 123, \"my_tenant\""}

      iex> Chroma.Database.get("my_database", "my_tenant")
      {:error, "Unauthorized: Invalid API key"}
  """
  @spec get(String.t(), String.t()) :: {:ok, t()} | {:error, String.t()}

  def get(name, tenant)
      when is_binary(name) and byte_size(name) > 2 and
             is_binary(tenant) and byte_size(tenant) > 2 do
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{name}"

    Req.get(url)
    |> handle_response()
  end

  def get(name, tenant) do
    {:error,
     "Database name and tenant must be strings, and greater than 2 characters; received: #{inspect(name)}, #{inspect(tenant)}"}
  end

  @doc """
  Deletes a database from ChromaDB.
  ## Parameters
  - `name`: The name of the database to be deleted.
  - `tenant`: The tenant to which the database belongs.
  ## Returns
  - `{:ok, %{}}`: If the database is deleted successfully.
  - `{:error, reason}`: If there is an error deleting the database.
  ## Examples
      iex> Chroma.Database.delete("my_database", "my_tenant")
      {:ok, %{}}

      iex> Chroma.Database.delete(123, "my_tenant")
      {:error, "Database name and tenant must be strings, and greater than 2 characters; received: 123, \"my_tenant\""}

      iex> Chroma.Database.delete("my_database", "my_tenant")
      {:error, "Unauthorized: Invalid API key"}
  """
  @spec delete(String.t(), String.t()) :: {:ok, %{}} | {:error, String.t()}

  def delete(name, tenant)
      when is_binary(name) and byte_size(name) > 2 and
             is_binary(tenant) and byte_size(tenant) > 2 do
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{name}"

    Req.delete(url)
    |> handle_response()
  end

  def delete(name, tenant) do
    {:error,
     "Database name and tenant must be strings, and greater than 2 characters; received: #{inspect(name)}, #{inspect(tenant)}"}
  end

  @doc """
  Lists all databases for a given tenant in ChromaDB.
  ## Parameters
  - `tenant`: The tenant for which to list databases.
  ## Returns
  - `{:ok, databases}`: If the databases are retrieved successfully.
  - `{:error, reason}`: If there is an error retrieving the databases.
  ## Examples
      iex> Chroma.Database.list("my_tenant")
      {:ok, [%Chroma.Database{id: "db1", name: "my_database", tenant: "my_tenant"}]}

      iex> Chroma.Database.list(123)
      {:error, "Tenant name must be a string, and greater than 2 characters; received: 123"}

      iex> Chroma.Database.list("my_tenant")
      {:error, "Unauthorized: Invalid API key"}
  """
  @spec list(String.t()) :: {:ok, [t()]} | {:error, String.t()}

  def list(tenant) when is_binary(tenant) and byte_size(tenant) > 2 do
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases"

    Req.get(url)
    |> handle_response_list()
  end

  def list(tenant) do
    {:error,
     "Tenant name must be a string, and greater than 2 characters; received: #{inspect(tenant)}"}
  end

  ##### # Private functions #####

  defp handle_response_list({:ok, %Req.Response{status: status, body: body}})
       when status in 200..299 and is_list(body) do
    if Enum.all?(body, &match?(%{"id" => _, "name" => _, "tenant" => _}, &1)) do
      databases =
        Enum.map(body, fn %{"id" => id, "name" => name, "tenant" => tenant} ->
          %Chroma.Database{id: id, name: name, tenant: tenant}
        end)

      {:ok, databases}
    else
      {:error, "Unexpected item format within response list: #{inspect(body)}"}
    end
  end

  defp handle_response_list({:ok, %Req.Response{status: status, body: body}})
       when status == 401 do
    {:error, "Unauthorized: #{inspect(body)}"}
  end

  defp handle_response_list({:ok, %Req.Response{status: status, body: body}})
       when status == 404 do
    {:error, "Not Found: #{inspect(body)}"}
  end

  defp handle_response_list({:ok, %Req.Response{status: status, body: body}})
       when status == 500 do
    {:error, "Server error: #{inspect(body)}"}
  end

  # You might also need a clause for non-list bodies or non-2xx statuses
  defp handle_response_list({:ok, %Req.Response{status: status}}) when status not in 200..299 do
    {:error, "HTTP Error: #{status}"}
  end

  defp handle_response_list({:ok, %Req.Response{body: body}}) when not is_list(body) do
    {:error, "Unexpected response format: Expected list, got #{inspect(body)}"}
  end

  defp handle_response_list({:error, reason}) do
    {:error, "Request failed: #{inspect(reason)}"}
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}})
       when status in 200..299 and is_map(body) do
    if map_size(body) == 0 do
      {:ok, %{}}
    else
      case body do
        %{"id" => id, "name" => name, "tenant" => tenant} ->
          {:ok, %Chroma.Database{id: id, name: name, tenant: tenant}}

        _ ->
          {:error, "Unexpected response format: #{inspect(body)}"}
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
