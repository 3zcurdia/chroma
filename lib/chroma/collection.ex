defmodule Chroma.Collection do
  alias Chroma

  @moduledoc """
  Provides functions to interact with ChromaDB collections, supporting both
  global operations (V1 API style) and operations within specific tenants
  and databases (V2 API style).

  Collections retrieved/created via V1 endpoints will have `tenant` and `database`
  fields set to `nil`. Functions specific to V2 operations require these fields
  to be non-nil strings.
  """

  # Removed default values for tenant and database
  defstruct tenant: nil,
            database: nil,
            id: nil,
            name: nil,
            metadata: nil

  # Updated type definition to allow nil for tenant/database
  @type t :: %__MODULE__{
          tenant: String.t() | nil,
          database: String.t() | nil,
          id: String.t() | nil,
          name: String.t() | nil,
          metadata: map() | nil
        }

  @doc """
  Queries a specific tenant's database  collection (V2 endpoint).

  Requires a `Chroma.Collection` struct retrieved via a V2 endpoint
  (must have non-nil `tenant`, `database`, and `id`).

  ## Parameters
  - `collection`: A `Chroma.Collection` struct with non-nil `tenant`, `database`, and `id`.
  - `kargs`: A keyword list or map containing query parameters.
    - `query_embeddings`: The embeddings to query against.
    - `include`: Optional fields to include in the response (default: `["metadatas", "documents", "distances"]`).
    - `results`: The number of results to return (default: 10).

  ## Examples
      iex> collection = Chroma.Collection.get!("my_collection", "my_tenant", "my_db") # Get a V2 collection
      iex> Chroma.Collection.query(collection, query_embeddings: [[1.1, 2.3, 3.2]])
      {:ok, %{"ids" => [["id1"]], ...}}
  """
  @spec query(t(), keyword() | map()) :: {:error, any()} | {:ok, map()}
  def query(%__MODULE__{tenant: tenant, database: database, id: id}, kargs)
      # Guards ensure V2 struct
      when is_binary(tenant) and is_binary(database) and is_binary(id) do
    {results, query_params} =
      kargs
      |> Enum.into(%{})
      |> Map.put_new(:include, ["metadatas", "documents", "distances"])
      |> Map.put_new(:results, 10)
      |> Map.pop!(:results)

    json_payload = Map.put(query_params, :n_results, results)
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}/query"

    url
    |> Req.post(json: json_payload)
    |> handle_json_response()
  end

  @doc """
  Creates a new `Chroma.Collection` struct from a map (API response data).

  Handles maps with or without `tenant` and `database` keys.
  Requires `id`, `name`, and `metadata` keys.
  """
  @spec new(map()) :: t() | no_return()
  def new(%{
        "tenant" => tenant,
        "database" => database,
        "id" => id,
        "name" => name,
        "metadata" => metadata
      })
      when is_binary(tenant) and is_binary(database) do
    %__MODULE__{
      tenant: tenant,
      database: database,
      id: id,
      name: name,
      metadata: metadata
    }
  end

  def new(%{"id" => id, "name" => name, "metadata" => metadata} = map)
      # Ensure tenant/db keys are NOT present to avoid ambiguity with Clause 1
      when is_map_key(map, "tenant") == false and is_map_key(map, "database") == false do
    %__MODULE__{
      tenant: nil,
      database: nil,
      id: id,
      name: name,
      metadata: metadata
    }
  end

  def new(other_map) do
    raise ArgumentError,
          "Cannot create Chroma.Collection struct. Map must contain 'id', 'name', 'metadata', and optionally 'tenant' and 'database'. Got: #{inspect(other_map)}"
  end

  @doc """
  Lists all collections using the V1 endpoint (global scope).

  Collections returned will have `tenant` and `database` set to `nil`.
  """
  @spec list() :: {:error, any()} | {:ok, list(t())}
  def list() do
    url = "#{Chroma.api_url()}/collections"

    url
    |> Req.get()
    # Will use new/1 to create V1 structs (tenant/db = nil)
    |> handle_response_list()
  end

  @doc """
  Lists all collections within a specific tenant and database (V2 endpoint).

  Collections returned will have `tenant` and `database` fields populated.
  """
  @spec list(String.t(), String.t()) :: {:error, any()} | {:ok, list(t())}
  def list(tenant, database) when is_binary(tenant) and is_binary(database) do
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections"

    url
    |> Req.get()
    # Will use new/1 to create V2 structs
    |> handle_response_list()
  end

  # --- Get Collection ---

  @doc """
  Gets a collection by name using the V1 endpoint (global scope).

  The returned collection struct will have `tenant` and `database` set to `nil`.
  """
  @spec get(String.t()) :: {:error, any()} | {:ok, t()}
  def get(name) do
    # Clause 1: Global get (V1)
    url = "#{Chroma.api_url()}/collections/#{name}"

    url
    |> Req.get()
    # Will use new/1 for V1 struct
    |> handle_response()
  end

  @doc """
  Gets a collection by name within a specific tenant and database (V2 endpoint).

  The returned collection struct will have `tenant` and `database` fields populated.
  """
  @spec get(String.t(), String.t(), String.t()) :: {:error, any()} | {:ok, t()}
  def get(name, tenant, database) do
    # Clause 2: Tenant/Database specific get (V2)
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{name}"

    url
    |> Req.get()
    # Will use new/1 for V2 struct
    |> handle_response()
  end

  @doc """
  Gets a collection by name (globally, V1), raising an error on failure.
  """
  @spec get!(String.t()) :: t()
  def get!(name) do
    # Bang Clause 1: Calls get/1
    name
    |> get()
    |> handle_response!()
  end

  @doc """
  Gets a collection by name within a specific tenant/database (V2), raising error on failure.
  """
  @spec get!(String.t(), String.t(), String.t()) :: t()
  def get!(name, tenant, database) do
    # Bang Clause 2: Calls get/3
    get(name, tenant, database)
    |> handle_response!()
  end

  # --- Create Collection ---

  @doc """
  Creates a collection using the V1 endpoint (global scope).

  The returned collection struct will have `tenant` and `database` set to `nil`.
  """
  @spec create(String.t(), map()) :: {:error, any()} | {:ok, t()}
  def create(name, metadata \\ %{}) do
    # Clause 1: Global create (V1)
    json = %{name: name, metadata: metadata, get_or_create: false}
    url = "#{Chroma.api_url()}/collections"

    url
    |> Req.post(json: json)
    # Will use new/1 for V1 struct
    |> handle_response()
  end

  @doc """
  Creates a collection within a specific tenant and database (V2 endpoint).

  The returned collection struct will have `tenant` and `database` fields populated.
  """
  @spec create(String.t(), String.t(), String.t(), map()) :: {:error, any()} | {:ok, t()}
  def create(name, tenant, database, metadata \\ %{}) do
    # Clause 2: Tenant/Database specific create (V2)
    json = %{name: name, metadata: metadata, get_or_create: false}
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections"

    url
    |> Req.post(json: json)
    # Will use new/1 for V2 struct
    |> handle_response()
  end

  @doc """
  Creates a collection (globally, V1), raising an error on failure.
  """
  @spec create!(String.t(), map()) :: t()
  def create!(name, metadata \\ %{}) do
    # Bang Clause 1: Calls create/2
    create(name, metadata)
    |> handle_response!()
  end

  @doc """
  Creates a collection within a specific tenant/database (V2), raising error on failure.
  """
  @spec create!(String.t(), String.t(), String.t(), map()) :: t()
  def create!(name, tenant, database, metadata \\ %{}) do
    # Bang Clause 2: Calls create/4
    create(name, tenant, database, metadata)
    |> handle_response!()
  end

  # --- Get or Create Collection ---

  @doc """
  Gets or creates a collection by name using the V1 endpoint (global scope).

  The returned collection struct will have `tenant` and `database` set to `nil`.
  """
  @spec get_or_create(String.t(), map()) :: {:error, any()} | {:ok, t()}
  def get_or_create(name, metadata \\ %{}) do
    # Clause 1: Global get_or_create (V1)
    json = %{name: name, metadata: metadata, get_or_create: true}
    url = "#{Chroma.api_url()}/collections"

    url
    |> Req.post(json: json)
    # Will use new/1 for V1 struct
    |> handle_response()
  end

  @doc """
  Gets or creates a collection by name within a specific tenant and database (V2 endpoint).

  The returned collection struct will have `tenant` and `database` fields populated.
  """
  @spec get_or_create(String.t(), String.t(), String.t(), map()) :: {:error, any()} | {:ok, t()}
  def get_or_create(name, tenant, database, metadata \\ %{}) do
    # Clause 2: Tenant/Database specific get_or_create (V2)
    json = %{name: name, metadata: metadata, get_or_create: true}
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections"

    url
    |> Req.post(json: json)
    # Will use new/1 for V2 struct
    |> handle_response()
  end

  @doc """
  Gets or creates a collection (globally, V1), raising an error on failure.
  """
  @spec get_or_create!(String.t(), map()) :: t()
  def get_or_create!(name, metadata \\ %{}) do
    # Bang Clause 1: Calls get_or_create/2
    get_or_create(name, metadata)
    |> handle_response!()
  end

  @doc """
  Gets or creates a collection within a specific tenant/database (V2), raising error on failure.
  """
  @spec get_or_create!(String.t(), String.t(), String.t(), map()) :: t()
  def get_or_create!(name, tenant, database, metadata \\ %{}) do
    # Bang Clause 2: Calls get_or_create/4
    get_or_create(name, tenant, database, metadata)
    |> handle_response!()
  end

  # --- Add Embeddings ---
  # Requires a V2 collection struct
  @doc """
  Adds a batch of embeddings to the specified collection (V2 endpoint).

  Requires a `Chroma.Collection` struct with non-nil `tenant`, `database`, and `id`.
  """
  @spec add(t(), map()) :: {:error, any()} | {:ok, any()}
  def add(%__MODULE__{tenant: tenant, database: database, id: id}, %{} = data)
      # Guards ensure V2 struct
      when is_binary(tenant) and is_binary(database) and is_binary(id) do
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}/add"

    url
    |> Req.post(json: data)
    |> handle_json_response()
  end

  # --- Update Embeddings ---
  # Requires a V2 collection struct
  @doc """
  Updates a batch of embeddings in the specified collection (V2 endpoint).

  Requires a `Chroma.Collection` struct with non-nil `tenant`, `database`, and `id`.
  """
  @spec update(t(), map()) :: {:error, any()} | {:ok, any()}
  def update(%__MODULE__{tenant: tenant, database: database, id: id}, %{} = data)
      # Guards ensure V2 struct
      when is_binary(tenant) and is_binary(database) and is_binary(id) do
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}/update"

    url
    |> Req.post(json: data)
    |> handle_json_response()
  end

  # --- Upsert Embeddings ---
  # Requires a V2 collection struct
  @doc """
  Upserts embeddings in the specified collection (V2 endpoint).

  Requires a `Chroma.Collection` struct with non-nil `tenant`, `database`, and `id`.
  """
  @spec upsert(t(), map()) :: {:error, any()} | {:ok, any()}
  def upsert(%__MODULE__{tenant: tenant, database: database, id: id}, data)
      # Guards ensure V2 struct
      when is_binary(tenant) and is_binary(database) and is_binary(id) and is_map(data) do
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}/upsert"

    url
    |> Req.post(json: data)
    |> handle_json_response()
  end

  # --- Modify Collection (Name/Metadata) ---
  # Requires a V2 collection struct
  @doc """
  Updates the name and/or metadata of a collection (V2 endpoint).

  Requires a `Chroma.Collection` struct with non-nil `tenant`, `database`, and `id`.
  """
  @spec modify(t(), keyword() | map()) :: {:error, any()} | {:ok, any()}
  def modify(%__MODULE__{} = collection, updates) when is_list(updates) do
    # Delegate keyword list to map clause
    args = Enum.into(updates, %{})
    modify(collection, args)
  end

  def modify(%__MODULE__{tenant: tenant, database: database, id: id}, updates)
      # Guards ensure V2 struct
      when is_binary(tenant) and is_binary(database) and is_binary(id) and is_map(updates) do
    # Prepare JSON payload
    json_payload =
      %{new_name: updates[:name], new_metadata: updates[:metadata]}
      |> Map.filter(fn {_, v} -> not is_nil(v) and v != %{} end)

    # Only send request if there's something to update
    if map_size(json_payload) > 0 do
      url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}"

      url
      |> Req.put(json: json_payload)
      |> handle_json_response()
    else
      # Nothing to update
      {:ok, nil}
    end
  end

  # --- Delete Collection ---
  # Requires a V2 collection struct
  @doc """
  Deletes a collection (V2 endpoint).

  Requires a `Chroma.Collection` struct with non-nil `tenant`, `database`, and `name`.
  """
  @spec delete(t()) :: {:error, any()} | {:ok, any()} | no_return()
  def delete(%__MODULE__{tenant: tenant, database: database, name: name})
      # Guards ensure V2 struct
      when is_binary(tenant) and is_binary(database) and is_binary(name) do
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{name}"

    url
    |> Req.delete()
    # Use bang version for delete
    |> handle_json_response!()
  end

  @doc """
  Counts all embeddings in the specified collection (V2 endpoint).

  Requires a `Chroma.Collection` struct with non-nil `tenant`, `database`, and `id`.
  """
  @spec count(t()) :: {:error, any()} | {:ok, integer()}
  def count(%__MODULE__{tenant: tenant, database: database, id: id})
      # Guards ensure V2 struct
      when is_binary(tenant) and is_binary(database) and is_binary(id) do
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}/count"

    case Req.get(url) do
      {:ok, %Req.Response{status: status, body: count_value}} when status in 200..299 ->
        if is_integer(count_value), do: {:ok, count_value}, else: {:error, "Invalid count value"}

      {:ok, %Req.Response{status: status, body: error_body}} ->
        {:error, "API Error (Status: #{status}): #{inspect(error_body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # --- Private Helper Functions ---

  # Handles responses expected to be a list of collections
  defp handle_response_list(req_result) do
    case handle_json_response(req_result) do
      # Uses the multi-clause new/1 to handle V1 or V2 list items
      {:ok, body_list} when is_list(body_list) ->
        try do
          collections = Enum.map(body_list, &new/1)
          {:ok, collections}
        rescue
          e in ArgumentError -> {:error, "Failed to parse collection list: #{inspect(e)}"}
        end

      {:ok, non_list_body} ->
        {:error, "API Error: Expected a list, got: #{inspect(non_list_body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Handles responses expected to be a single collection
  defp handle_response(req_result) do
    case handle_json_response(req_result) do
      {:ok, body_map} when is_map(body_map) ->
        try do
          {:ok, new(body_map)}
        rescue
          e in ArgumentError -> {:error, "Failed to parse collection: #{inspect(e)}"}
        end

      {:ok, non_map_body} ->
        {:error, "API Error: Expected a map, got: #{inspect(non_map_body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Bang version of handle_response
  defp handle_response!(response_tuple) do
    case response_tuple do
      {:ok, body} -> body
      {:error, reason} -> raise inspect(reason)
    end
  end

  defp handle_json_response({:ok, %Req.Response{status: status, body: body}}) do
    case status do
      code when code in 200..299 -> {:ok, body}
      _ -> {:error, Map.get(body, "error", "API Error (Status: #{status})")}
    end
  end

  defp handle_json_response({:error, _reason} = error_tuple), do: error_tuple
  # defp handle_json_response(other), do: {:error, "Unexpected Req response: #{inspect(other)}"}

  # Bang version of handle_json_response
  defp handle_json_response!(req_result) do
    case handle_json_response(req_result) do
      {:ok, body} -> body
      # Consider raising a custom ChromaError
      {:error, reason} -> raise inspect(reason)
    end
  end
end
