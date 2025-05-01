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

  @spec query(Chroma.Collection.t(), keyword()) :: {:error, any()} | {:ok, any()}
  @doc """
  It allows to query the database for similar embeddings.

  Handles both v1 and v2 API versions based on the collection struct.

  ## Parameters

    - **collection**: The Chroma.Collection struct.
    - **query_embeddings**: A list of embeddings to query. (Required in kargs)
    - **results**: The number of results to return. (Optional in kargs, defaults to 10)
    - **where**: A map of metadata fields to filter by. (Optional in kargs)
    - **where_document**: A map of document fields to filter by. (Optional in kargs)
    - **include**: List of items to include in the response (e.g., "metadatas", "documents", "distances"). (Optional in kargs, defaults to ["metadatas", "documents", "distances"])

  ## Examples

    # v2 API example
      iex> v2_collection = %Chroma.Collection{tenant: "my_tenant", database: "my_database", id: "v2_collection_id"}
      iex> # Assuming serving is loaded and produces embeddings
      iex> query_embs = [[1.1, 2.1, 3.1], [4.1, 5.1, 6.1]] # Example embeddings
      iex> # Assuming Req and handle_json_response are available
      iex> # Chroma.Collection.query(v2_collection, query_embeddings: query_embs, results: 5, where: %{"source": "documentA"})
      # Expected to call v2 API endpoint

    # v1 API example
      iex> v1_collection = %Chroma.Collection{id: "v1_collection_id"} # tenant and database are nil or not present
      iex> query_embs = [[7.1, 8.1, 9.1]] # Example embeddings
      iex> # Assuming Req and handle_json_response are available
      iex> # Chroma.Collection.query(v1_collection, query_embeddings: query_embs)
      # Expected to call v1 API endpoint

  """

  def query(%Chroma.Collection{tenant: tenant, database: database, id: id}, kargs)
      when is_binary(tenant) and tenant != "" and
             is_binary(database) and database != "" and
             is_binary(id) and id != "" do
    {n_results, map} =
      kargs
      |> Enum.into(%{})
      |> Map.put_new(:include, ["metadatas", "documents", "distances"])
      |> Map.put_new(:n_results, 10)
      |> Map.pop(:n_results)

    case Map.fetch(map, :query_embeddings) do
      {:ok, query_embeddings} ->
        json_payload =
          map
          |> Map.put(:n_results, n_results)
          |> Map.put(:query_embeddings, query_embeddings)

        url =
          "#{Chroma.api_url()}/api/v1/tenants/#{tenant}/databases/#{database}/collections/#{id}/query"

        url
        |> Req.post(json: json_payload)
        |> handle_json_response()

      :error ->
        {:error, "Missing required parameter in kargs: :query_embeddings"}
    end
  end

  def query(%Chroma.Collection{id: id}, kargs)
      when is_binary(id) and id != "" do
    {n_results, map} =
      kargs
      |> Enum.into(%{})
      |> Map.put_new(:include, ["metadatas", "documents", "distances"])
      |> Map.put_new(:n_results, 10)
      |> Map.pop(:n_results)

    case Map.fetch(map, :query_embeddings) do
      {:ok, query_embeddings} ->
        json_payload =
          map
          |> Map.put(:n_results, n_results)
          |> Map.put(:query_embeddings, query_embeddings)

        url = "#{Chroma.api_url()}/collections/#{id}/query"

        url
        |> Req.post(json: json_payload)
        |> handle_json_response()

      :error ->
        {:error, "Missing required parameter in kargs: :query_embeddings"}
    end
  end

  def query(%Chroma.Collection{} = collection, _kargs) do
    {:error,
     "Invalid Chroma.Collection struct for query: #{inspect(collection)}. Ensure id is a non-empty string, and for v2, tenant and database are also non-empty strings."}
  end

  def query(other, _kargs),
    do:
      {:error,
       "Invalid first argument for query. Expected Chroma.Collection struct, got: #{inspect(other)}"}

  @spec new(map) :: {:ok, Chroma.Collection.t()} | {:error, String.t()}
  @doc """
  Creates a new `Chroma.Collection` struct from a map of attributes.

  This function handles different input map structures based on the API version
  or context from which the data originates.

  ## Supported Map Structures:

  1.  **v2-like:** Requires keys `"tenant"`, `"database"`, `"id"`, `"name"`, and `"metadata"`.
      All required values should be strings, except for `"metadata"` which should be a map.
  2.  **v1-like:** Requires keys `"id"`, `"name"`, and `"metadata"`.
      `"id"` and `"name"` should be strings, and `"metadata"` should be a map.
      `tenant` and `database` fields in the struct will be set to `nil`.

  ## Parameters

    - **attrs**: A map containing the collection attributes.

  ## Returns

    - `{:ok, %Chroma.Collection{}}` if the map matches a supported structure and
      contains valid data.
    - `{:error, reason}` if the map does not match any supported structure
      or contains invalid data.

  ## Examples

      iex> Chroma.Collection.new(%{"tenant" => "my_tenant", "database" => "my_database", "id" => "v2_coll", "name" => "V2 Collection", "metadata" => %{"source" => "api"}})
      {:ok, %Chroma.Collection{tenant: "my_tenant", database: "my_database", id: "v2_coll", name: "V2 Collection", metadata: %{"source" => "api"}}}

      iex> Chroma.Collection.new(%{"id" => "v1_coll", "name" => "V1 Collection", "metadata" => %{}})
      {:ok, %Chroma.Collection{tenant: nil, database: nil, id: "v1_coll", name: "V1 Collection", metadata: %{}}}

      iex> Chroma.Collection.new(%{"id" => "invalid", "name" => "Missing Metadata"})
      {:error, "Input map does not match any supported Chroma.Collection structure."}

      iex> Chroma.Collection.new(%{"tenant" => "t", "database" => "d", "id" => "i", "name" => "n", "metadata" => "not a map"})
      {:error, "Input map does not match any supported Chroma.Collection structure."} # Or a more specific validation error if added later

  """

  def new(%{
        "tenant" => tenant,
        "database" => database,
        "id" => id,
        "name" => name,
        "metadata" => metadata
      })
      when is_binary(tenant) and is_binary(database) and is_binary(id) and is_binary(name) and
             is_map(metadata) do
    {:ok,
     %Chroma.Collection{
       tenant: tenant,
       database: database,
       id: id,
       name: name,
       metadata: metadata
     }}
  end

  def new(%{"id" => id, "name" => name, "metadata" => metadata})
      when is_binary(id) and is_binary(name) and is_map(metadata) do
    # Set tenant and database to nil for v1
    {:ok, %Chroma.Collection{tenant: nil, database: nil, id: id, name: name, metadata: metadata}}
  end

  def new(attrs) when is_map(attrs) do
    {:error, "Input map does not match any supported Chroma.Collection structure."}
  end

  def new(other) do
    {:error, "Invalid input for Chroma.Collection.new. Expected a map, got: #{inspect(other)}"}
  end

  @spec list() :: {:error, any()} | {:ok, list(Chroma.Collection.t())}
  @spec list(String.t(), String.t()) :: {:error, any()} | {:ok, list(Chroma.Collection.t())}
  @doc """
  Lists all stored collections in the database.

  This function supports both v1 and v2 API endpoints.

  - Calling `list()` will use the v1 API endpoint.
  - Calling `list(tenant, database)` will use the v2 API endpoint, requiring
    valid tenant and database strings.

  ## Examples

      # v1 API example
      iex> # Assuming Chroma.api_url() points to a v1 compatible endpoint
      iex> # Chroma.Collection.list()
      # Expected to call v1 API endpoint and return {:ok, [%Chroma.Collection{...}, ...]}

      # v2 API example
      iex> # Assuming Chroma.api_url() points to a v2 compatible endpoint
      iex> # Chroma.Collection.list("my_tenant", "my_database")
      # Expected to call v2 API endpoint and return {:ok, [%Chroma.Collection{...}, ...]}

      iex> # Invalid v2 call
      iex> # Chroma.Collection.list("invalid_tenant", "")
      # Expected to return {:error, "Invalid tenant or database provided..."}

  """

  # Clause for v1 API: Takes no arguments.
  def list do
    "#{Chroma.api_url()}/collections"
    |> Req.get()
    |> handle_response_list()
  end

  def list(tenant, database)
      when is_binary(tenant) and tenant != "" and
             is_binary(database) and database != "" do
    url = "#{Chroma.api_url()}/api/v1/tenants/#{tenant}/databases/#{database}/collections"

    url
    |> Req.get()
    # Assuming handle_response_list/1 is defined elsewhere
    |> handle_response_list()
  end

  # Catch-all clause for list/2 with invalid tenant/database inputs.
  def list(tenant, database),
    do:
      {:error,
       "Invalid tenant or database provided for listing collections. Expected non-empty strings, got: tenant=#{inspect(tenant)}, database=#{inspect(database)}"}

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

  @doc """
  Adds a batch of embeddings to the specified collection (V1 endpoint).
  """
  @spec add(id :: String.t(), data :: map()) :: {:error, any()} | {:ok, any()}
  def add(id, %{} = data) when is_binary(id) do
    url = "#{Chroma.api_url()}/collections/#{id}/add"

    url
    |> Req.post(json: data)
    |> handle_json_response()
  end

  @doc """
  Adds a batch of embeddings to the specified collection (V2 endpoint).
  """
  @spec add(tenant :: String.t(), database :: String.t(), id :: String.t(), data :: map()) ::
          {:error, any()} | {:ok, any()}
  def add(tenant, database, id, %{} = data)
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
