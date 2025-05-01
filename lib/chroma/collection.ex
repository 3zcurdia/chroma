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

  defstruct [
    :id,
    :name,
    :metadata,
    :tenant,
    :database,
    :configuration_json,
    :dimension,
    :log_position,
    :version
  ]

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
          "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}/query"

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
        "metadata" => metadata,
        "configuration_json" => configuration_json,
        "dimension" => dimension,
        "log_position" => log_position,
        "version" => version
      })
      when is_binary(tenant) and is_binary(database) and is_binary(id) and is_binary(name) and
             is_map(metadata) do
    {:ok,
     %Chroma.Collection{
       tenant: tenant,
       database: database,
       id: id,
       name: name,
       metadata: metadata,
       configuration_json: configuration_json,
       dimension: dimension,
       log_position: log_position,
       version: version
     }}
  end

  def new(%{"id" => id, "name" => name, "metadata" => metadata})
      when is_binary(id) and is_binary(name) and is_map(metadata) do
    # Set tenant and database to nil for v1
    {:ok,
     %Chroma.Collection{
       tenant: nil,
       database: nil,
       id: id,
       name: name,
       metadata: metadata,
       configuration_json: nil,
       dimension: nil,
       log_position: nil,
       version: nil
     }}
  end

  def new(attrs) when is_map(attrs) do
    {:error,
     "Input map does not match any supported Chroma.Collection structure. #{inspect(attrs)}"}
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
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections"

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

  @spec get(String.t()) :: {:error, any()} | {:ok, Chroma.Collection.t()}
  @spec get(String.t(), String.t(), String.t()) :: {:error, any()} | {:ok, Chroma.Collection.t()}
  @doc """
  Gets a single collection by name (v1 API) or by tenant, database, and ID (v2 API).

  - Calling `get(name)` will use the v1 API endpoint to get a collection by its name.
  - Calling `get(tenant, database, id)` will use the v2 API endpoint to get a collection
    by its tenant, database, and ID.

  ## Parameters

    - **name**: The name of the collection (for v1 API).
    - **tenant**: The tenant of the collection (for v2 API).
    - **database**: The database of the collection (for v2 API).
    - **id**: The ID of the collection (for v2 API).

  ## Returns

    - `{:ok, %Chroma.Collection{}}` if the collection is found.
    - `{:error, reason}` if the collection is not found or an error occurs.

  ## Examples

      # v1 API example
      iex> # Assuming Chroma.api_url() points to a v1 compatible endpoint
      iex> # Chroma.Collection.get("my_v1_collection_name")
      # Expected to call v1 API endpoint and return {:ok, %Chroma.Collection{...}}

      # v2 API example
      iex> # Assuming Chroma.api_url() points to a v2 compatible endpoint
      iex> # Chroma.Collection.get("my_tenant", "my_database", "my_v2_collection_id")
      # Expected to call v2 API endpoint and return {:ok, %Chroma.Collection{...}}

      iex> # Invalid v1 call
      iex> # Chroma.Collection.get("")
      # Expected to return {:error, "Invalid collection name..."}

      iex> # Invalid v2 call
      iex> # Chroma.Collection.get("t", "", "i")
      # Expected to return {:error, "Invalid tenant, database, or ID..."}

  """
  def get(name) when is_binary(name) and name != "" do
    "#{Chroma.api_url()}/collections/#{name}"
    |> Req.get()
    # Assuming handle_response/1 is defined elsewhere
    |> handle_response()
  end

  def get(name) do
    {:error,
     "Invalid collection name provided for get/1. Expected a non-empty string, got: #{inspect(name)}"}
  end

  def get(tenant, database, id)
      when is_binary(tenant) and tenant != "" and
             is_binary(database) and database != "" and
             is_binary(id) and id != "" do
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}"

    url
    |> Req.get()
    |> handle_response()
  end

  def get(tenant, database, id) do
    {:error,
     "Invalid tenant, database, or ID provided for get/3. Expected non-empty strings, got: tenant=#{inspect(tenant)}, database=#{inspect(database)}, id=#{inspect(id)}"}
  end

  @spec create(String.t(), map()) :: {:error, any()} | {:ok, Chroma.Collection.t()}
  @spec create(String.t(), String.t(), String.t(), map()) ::
          {:error, any()} | {:ok, Chroma.Collection.t()}
  @doc """
  Creates a new collection in the database.

  This function supports both v1 and v2 API endpoints.

  - Calling `create(name, metadata \\ %{})` will use the v1 API endpoint,
    creating a collection with the given name and metadata.
  - Calling `create(tenant, database, name, metadata \\ %{})` will use the v2 API endpoint,
    creating a collection within the specified tenant and database with the given name and metadata.

  ## Parameters

    - **name**: The name of the collection (for both v1 and v2 API).
    - **metadata**: An optional map of metadata for the collection (defaults to %{}).
    - **tenant**: The tenant for the new collection (for v2 API).
    - **database**: The database for the new collection (for v2 API).

  ## Returns

    - `{:ok, %Chroma.Collection{}}` if the collection is created successfully.
    - `{:error, reason}` if the creation fails or invalid inputs are provided.

  ## Examples

      # v1 API example
      iex> # Assuming Chroma.api_url() points to a v1 compatible endpoint
      iex> # Chroma.Collection.create("my_new_v1_collection", %{type: "example"})
      # Expected to call v1 API endpoint and return {:ok, %Chroma.Collection{...}}

      # v2 API example
      iex> # Assuming Chroma.api_url() points to a v2 compatible endpoint
      iex> # Chroma.Collection.create("my_tenant", "my_database", "my_new_v2_collection", %{source: "elixir"})
      # Expected to call v2 API endpoint and return {:ok, %Chroma.Collection{...}}

      iex> # Invalid v1 call
      iex> # Chroma.Collection.create("", %{})
      # Expected to return {:error, "Invalid collection name..."}

      iex> # Invalid v2 call
      iex> # Chroma.Collection.create("t", "d", "", %{})
      # Expected to return {:error, "Invalid collection name..."}

  """

  def create(tenant, database, name, metadata \\ %{})

  def create(tenant, database, name, metadata)
      when is_binary(tenant) and tenant != "" and
             is_binary(database) and database != "" and
             is_binary(name) and name != "" and
             is_map(metadata) do
    IO.puts(
      "Using v2 API for creating collection '#{name}' in tenant '#{tenant}', database '#{database}'."
    )

    json = %{name: name, metadata: metadata, get_or_create: false}
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections"

    url
    |> Req.post(json: json)
    |> handle_response()
  end

  def create(tenant, database, name, metadata) do
    {:error,
     "Invalid tenant, database, name, or metadata provided for create/4. Expected tenant, database, name as non-empty strings, metadata as map. Got: tenant=#{inspect(tenant)}, database=#{inspect(database)}, name=#{inspect(name)}, metadata=#{inspect(metadata)}"}
  end

  def create(name, metadata \\ %{})

  def create(name, metadata)
      when is_binary(name) and name != "" and
             is_map(metadata) do
    IO.puts("Using v1 API for creating collection '#{name}'.")
    json = %{name: name, metadata: metadata, get_or_create: false}
    url = "#{Chroma.api_url()}/collections"

    url
    |> Req.post(json: json)
    |> handle_response()
  end

  def create(name, metadata) do
    {:error,
     "Invalid collection name or metadata provided for create/2. Expected name as non-empty string, metadata as map. Got: name=#{inspect(name)}, metadata=#{inspect(metadata)}"}
  end

  @spec get_or_create(String.t(), map()) :: {:error, any()} | {:ok, Chroma.Collection.t()}
  @spec get_or_create(String.t(), String.t(), String.t(), map()) ::
          {:error, any()} | {:ok, Chroma.Collection.t()}
  @doc """
  Gets or creates a collection in the database.

  This function supports both v1 and v2 API endpoints. If a collection with the
  given name (v1) or tenant/database/name (v2) exists, it will be returned.
  Otherwise, a new collection will be created.

  - Calling `get_or_create(name, metadata \\ %{})` will use the v1 API endpoint.
  - Calling `get_or_create(tenant, database, name, metadata \\ %{})` will use the v2 API endpoint.

  ## Parameters

    - **name**: The name of the collection (for both v1 and v2 API).
    - **metadata**: An optional map of metadata for the collection (defaults to %{}).
    - **tenant**: The tenant for the collection (for v2 API).
    - **database**: The database for the collection (for v2 API).

  ## Returns

    - `{:ok, %Chroma.Collection{}}` if the collection is successfully retrieved or created.
    - `{:error, reason}` if the operation fails or invalid inputs are provided.

  ## Examples

      # v1 API example
      iex> # Assuming Chroma.api_url() points to a v1 compatible endpoint
      iex> # Chroma.Collection.get_or_create("my_v1_collection", %{type: "example"})
      # Expected to call v1 API endpoint and return {:ok, %Chroma.Collection{...}}

      # v2 API example
      iex> # Assuming Chroma.api_url() points to a v2 compatible endpoint
      iex> # Chroma.Collection.get_or_create("my_tenant", "my_database", "my_v2_collection", %{source: "elixir"})
      # Expected to call v2 API endpoint and return {:ok, %Chroma.Collection{...}}

      iex> # Invalid v1 call
      iex> # Chroma.Collection.get_or_create("", %{})
      # Expected to return {:error, "Invalid collection name..."}

      iex> # Invalid v2 call
      iex> # Chroma.Collection.get_or_create("t", "d", "", %{})
      # Expected to return {:error, "Invalid collection name..."}

  """

  def get_or_create(tenant, database, name, metadata \\ %{})

  def get_or_create(tenant, database, name, metadata)
      when is_binary(tenant) and tenant != "" and
             is_binary(database) and database != "" and
             is_binary(name) and name != "" and
             is_map(metadata) do
    json = %{name: name, metadata: metadata, get_or_create: true}
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections"

    url
    |> Req.post(json: json)
    |> handle_response()
  end

  def get_or_create(tenant, database, name, metadata),
    do:
      {:error,
       "Invalid tenant, database, name, or metadata provided for get_or_create/4. Expected tenant, database, name as non-empty strings, metadata as map. Got: tenant=#{inspect(tenant)}, database=#{inspect(database)}, name=#{inspect(name)}, metadata=#{inspect(metadata)}"}

  def get_or_create(name, metadata \\ %{})

  def get_or_create(name, metadata)
      when is_binary(name) and name != "" and
             is_map(metadata) do
    json = %{name: name, metadata: metadata, get_or_create: true}
    url = "#{Chroma.api_url()}/collections"

    url
    |> Req.post(json: json)
    |> handle_response()
  end

  def get_or_create(name, metadata),
    do:
      {:error,
       "Invalid collection name or metadata provided for get_or_create/2. Expected name as non-empty string, metadata as map. Got: name=#{inspect(name)}, metadata=#{inspect(metadata)}"}

  # Assuming handle_json_response! returns any
  @spec add(Chroma.Collection.t(), map()) :: any()
  @doc """
  Adds a batch of embeddings, documents, and/or metadata to a collection.

  This function supports both v1 and v2 API endpoints based on the provided
  Chroma.Collection struct.

  ## Parameters

    - **collection**: The Chroma.Collection struct representing the target collection.
      For v2, this struct must have non-empty `tenant`, `database`, and `id`.
      For v1, this struct must have a non-empty `id`.
    - **data**: A map containing the data to add. This map should include at least one
      of the following keys: `:embeddings`, `:documents`, `:ids`.
      Optional keys include `:metadatas` and `:uris`.

      Example data map:
      %{
        embeddings: [[1.1, 2.2, 3.3], [4.4, 5.5, 6.6]],
        documents: ["doc1 content", "doc2 content"],
        ids: ["id1", "id2"],
        metadatas: [%{source: "a"}, %{source: "b"}]
      }

  ## Returns

    The result of the underlying HTTP request handling, typically `nil` on success
    for the `handle_json_response!/1` helper, or raises an error on failure.

  ## Examples

      # Assuming you have a v1 or v2 collection struct and a data map
      iex> v1_collection = %Chroma.Collection{id: "v1_coll_id"}
      iex> v2_collection = %Chroma.Collection{tenant: "t", database: "d", id: "v2_coll_id"}
      iex> data_to_add = %{
      ...>   embeddings: [[1.0, 2.0]],
      ...>   documents: ["test document"],
      ...>   ids: ["test_id"]
      ...> }
      iex> # Assuming handle_json_response! is defined
      iex> # Chroma.Collection.add(v1_collection, data_to_add)
      # Expected to call v1 API endpoint and return nil or raise

      iex> # Chroma.Collection.add(v2_collection, data_to_add)
      # Expected to call v2 API endpoint and return nil or raise

      iex> # Invalid collection struct
      iex> # Chroma.Collection.add(%Chroma.Collection{}, data_to_add)
      # Expected to return {:error, "Invalid Chroma.Collection struct..."}

  """

  def add(%Chroma.Collection{tenant: tenant, database: database, id: id}, %{} = data)
      when is_binary(tenant) and tenant != "" and
             is_binary(database) and database != "" and
             is_binary(id) and id != "" do
    url =
      "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}/add"

    url
    |> Req.post(json: data)
    |> handle_json_response!()
  end

  def add(%Chroma.Collection{id: id}, %{} = data)
      when is_binary(id) and id != "" do
    url = "#{Chroma.api_url()}/collections/#{id}/add"

    url
    |> Req.post(json: data)
    |> handle_json_response!()
  end

  def add(%Chroma.Collection{} = collection, data),
    do:
      {:error,
       "Invalid Chroma.Collection struct or data map provided for add/2. Ensure collection has a non-empty id (and tenant/database for v2) and data is a map. Got: collection=#{inspect(collection)}, data=#{inspect(data)}"}

  def add(other, data),
    do:
      {:error,
       "Invalid first argument for add. Expected Chroma.Collection struct, got: #{inspect(other)}. Data: #{inspect(data)}"}

  # Assuming handle_json_response returns {:ok, body} or {:error, reason}
  @spec update(Chroma.Collection.t(), map()) :: {:error, any()} | {:ok, any()}
  @doc """
  Updates a batch of embeddings, documents, and/or metadata in a collection.

  This function supports both v1 and v2 API endpoints based on the provided
  Chroma.Collection struct.

  ## Parameters

    - **collection**: The Chroma.Collection struct representing the target collection.
      For v2, this struct must have non-empty `tenant`, `database`, and `id`.
      For v1, this struct must have a non-empty `id`.
    - **data**: A map containing the data to update. This map should include at least one
      of the following keys: `:embeddings`, `:documents`, `:ids`, `:metadatas`, `:uris`.
      The `:ids` key is typically required to identify which items to update.

      Example data map:
      %{
        ids: ["id1", "id2"],
        embeddings: [[10.1, 11.1, 12.1], [13.1, 14.1, 15.1]], # Update embeddings for id1 and id2
        metadatas: [%{status: "processed"}, %{status: "processed"}] # Update metadata for id1 and id2
      }

  ## Returns

    - `{:ok, any()}` if the update is successful. The exact content of `any()`
      depends on the Chroma API response and the `handle_json_response/1` helper.
    - `{:error, any()}` if the update fails or invalid inputs are provided.

  ## Examples

      # Assuming you have a v1 or v2 collection struct and a data map for update
      iex> v1_collection = %Chroma.Collection{id: "v1_coll_id"}
      iex> v2_collection = %Chroma.Collection{tenant: "t", database: "d", id: "v2_coll_id"}
      iex> data_to_update = %{
      ...>   ids: ["existing_id_1"],
      ...>   documents: ["updated document content"]
      ...> }
      iex> # Assuming handle_json_response is defined
      iex> # Chroma.Collection.update(v1_collection, data_to_update)
      # Expected to call v1 API endpoint and return {:ok, ...} or {:error, ...}

      iex> # Chroma.Collection.update(v2_collection, data_to_update)
      # Expected to call v2 API endpoint and return {:ok, ...} or {:error, ...}

      iex> # Invalid collection struct
      iex> # Chroma.Collection.update(%Chroma.Collection{}, data_to_update)
      # Expected to return {:error, "Invalid Chroma.Collection struct..."}

  """

  def update(%Chroma.Collection{tenant: tenant, database: database, id: id}, %{} = data)
      when is_binary(tenant) and tenant != "" and
             is_binary(database) and database != "" and
             is_binary(id) and id != "" do
    url =
      "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}/update"

    url
    |> Req.post(json: data)
    |> handle_json_response()
  end

  def update(%Chroma.Collection{id: id}, %{} = data)
      when is_binary(id) and id != "" do
    IO.puts("Using v1 API for updating data in collection '#{id}'.")

    url = "#{Chroma.api_url()}/collections/#{id}/update"

    url
    |> Req.post(json: data)
    |> handle_json_response()
  end

  def update(%Chroma.Collection{} = collection, data),
    do:
      {:error,
       "Invalid Chroma.Collection struct or data map provided for update/2. Ensure collection has a non-empty id (and tenant/database for v2) and data is a map. Got: collection=#{inspect(collection)}, data=#{inspect(data)}"}

  def update(other, data),
    do:
      {:error,
       "Invalid first argument for update. Expected Chroma.Collection struct, got: #{inspect(other)}. Data: #{inspect(data)}"}

  @spec upsert(Chroma.Collection.t(), map()) :: {:error, any()} | {:ok, any()}
  @doc """
  Upserts a batch of embeddings, documents, and/or metadata in a collection.

  This function supports both v1 and v2 API endpoints based on the provided
  Chroma.Collection struct. Upsert means that if an item with a given ID
  exists, it will be updated; otherwise, it will be created.

  ## Parameters

    - **collection**: The Chroma.Collection struct representing the target collection.
      For v2, this struct must have non-empty `tenant`, `database`, and `id`.
      For v1, this struct must have a non-empty `id`.
    - **data**: A map containing the data to upsert. This map should include at least one
      of the following keys: `:embeddings`, `:documents`, `:ids`, `:metadatas`, `:uris`.
      The `:ids` key is typically required.

      Example data map:
      %{
        ids: ["id1", "id2"],
        embeddings: [[10.1, 11.1, 12.1], [13.1, 14.1, 15.1]], # Upsert embeddings for id1 and id2
        documents: ["doc1 content", "doc2 content"], # Upsert documents for id1 and id2
        metadatas: [%{status: "processed"}, %{status: "processed"}] # Upsert metadata for id1 and id2
      }

  ## Returns

    - `{:ok, any()}` if the upsert is successful. The exact content of `any()`
      depends on the Chroma API response and the `handle_json_response/1` helper.
    - `{:error, any()}` if the upsert fails or invalid inputs are provided.

  ## Examples

      # Assuming you have a v1 or v2 collection struct and a data map for upsert
      iex> v1_collection = %Chroma.Collection{id: "v1_coll_id"}
      iex> v2_collection = %Chroma.Collection{tenant: "t", database: "d", id: "v2_coll_id"}
      iex> data_to_upsert = %{
      ...>   ids: ["new_id_1", "existing_id_2"],
      ...>   documents: ["new document content", "updated document content"]
      ...> }
      iex> # Assuming handle_json_response is defined
      iex> # Chroma.Collection.upsert(v1_collection, data_to_upsert)
      # Expected to call v1 API endpoint and return {:ok, ...} or {:error, ...}

      iex> # Chroma.Collection.upsert(v2_collection, data_to_upsert)
      # Expected to call v2 API endpoint and return {:ok, ...} or {:error, ...}

      iex> # Invalid collection struct
      iex> # Chroma.Collection.upsert(%Chroma.Collection{}, data_to_upsert)
      # Expected to return {:error, "Invalid Chroma.Collection struct..."}

  """
  def upsert(%Chroma.Collection{tenant: tenant, database: database, id: id}, %{} = data)
      when is_binary(tenant) and tenant != "" and
             is_binary(database) and database != "" and
             is_binary(id) and id != "" do
    url =
      "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}/upsert"

    url
    |> Req.post(json: data)
    |> handle_json_response()
  end

  def upsert(%Chroma.Collection{id: id}, %{} = data)
      when is_binary(id) and id != "" do
    IO.puts("Using v1 API for upserting data in collection '#{id}'.")
    url = "#{Chroma.api_url()}/collections/#{id}/upsert"

    url
    |> Req.post(json: data)
    |> handle_json_response()
  end

  def upsert(%Chroma.Collection{} = collection, data),
    do:
      {:error,
       "Invalid Chroma.Collection struct or data map provided for upsert/2. Ensure collection has a non-empty id (and tenant/database for v2) and data is a map. Got: collection=#{inspect(collection)}, data=#{inspect(data)}"}

  def upsert(other, data),
    do:
      {:error,
       "Invalid first argument for upsert. Expected Chroma.Collection struct, got: #{inspect(other)}. Data: #{inspect(data)}"}

  @spec modify(Chroma.Collection.t(), maybe_improper_list | map()) ::
          {:error, any()} | {:ok, any()}
  @doc """
  Updates the name and/or metadata of a collection.

  This function supports both v1 and v2 API endpoints based on the provided
  Chroma.Collection struct.

  ## Parameters

    - **collection**: The Chroma.Collection struct representing the target collection.
      For v2, this struct must have non-empty `tenant`, `database`, and `id`.
      For v1, this struct must have a non-empty `id`.
    - **data**: A map or keyword list containing the data to update.
      Supported keys are `:new_name` (string) and `:new_metadata` (map).
      At least one of these keys should be present.

      Example data map/keyword list:
      `%{new_name: "updated_name", new_metadata: %{status: "active"}}`
      `[new_name: "updated_name"]`

  ## Returns

    - `{:ok, any()}` if the update is successful. The exact content of `any()`
      depends on the Chroma API response and the `handle_json_response/1` helper.
    - `{:error, any()}` if the update fails or invalid inputs are provided.

  ## Examples

      # Assuming you have a v1 or v2 collection struct and data for modification
      iex> v1_collection = %Chroma.Collection{id: "v1_coll_id"}
      iex> v2_collection = %Chroma.Collection{tenant: "t", database: "d", id: "v2_coll_id"}
      iex> data_to_modify = %{new_name: "renamed_collection", new_metadata: %{version: "2"}}
      iex> # Assuming handle_json_response is defined
      iex> # Chroma.Collection.modify(v1_collection, data_to_modify)
      # Expected to call v1 API endpoint and return {:ok, ...} or {:error, ...}

      iex> # Chroma.Collection.modify(v2_collection, data_to_modify)
      # Expected to call v2 API endpoint and return {:ok, ...} or {:error, ...}

      iex> # Invalid collection struct
      iex> # Chroma.Collection.modify(%Chroma.Collection{}, data_to_modify)
      # Expected to return {:error, "Invalid Chroma.Collection struct..."}

      iex> # Invalid data input
      iex> # Chroma.Collection.modify(v1_collection, "not a map or list")
      # Expected to return {:error, "Invalid data map or keyword list..."}

  """

  def modify(%Chroma.Collection{} = collection, kwargs) when is_list(kwargs) do
    args =
      kwargs
      |> Enum.into(%{})

    modify(collection, args)
  end

  def modify(%Chroma.Collection{tenant: tenant, database: database, id: id}, %{} = args)
      when is_binary(tenant) and tenant != "" and
             is_binary(database) and database != "" and
             is_binary(id) and id != "" do
    json =
      %{new_name: args[:new_name], new_metadata: args[:new_metadata]}
      |> Map.filter(fn {_, v} -> v != nil and v != %{} and v != [] end)

    if map_size(json) == 0 do
      {:error, "No valid update fields (:new_name or :new_metadata) provided in the data map."}
    else
      url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}"

      url
      |> Req.put(json: json)
      |> handle_json_response()
    end
  end

  def modify(%Chroma.Collection{id: id}, %{} = args)
      when is_binary(id) and id != "" do
    json =
      %{new_name: args[:new_name], new_metadata: args[:new_metadata]}
      |> Map.filter(fn {_, v} -> v != nil and v != %{} and v != [] end)

    if map_size(json) == 0 do
      {:error, "No valid update fields (:new_name or :new_metadata) provided in the data map."}
    else
      url = "#{Chroma.api_url()}/collections/#{id}"

      url
      |> Req.put(json: json)
      |> handle_json_response()
    end
  end

  def modify(%Chroma.Collection{} = collection, data) when is_map(data),
    do:
      {:error,
       "Invalid Chroma.Collection struct provided for modify/2. Ensure collection has a non-empty id (and tenant/database for v2). Got: collection=#{inspect(collection)}"}

  def modify(other, data),
    do:
      {:error,
       "Invalid arguments for modify. Expected Chroma.Collection struct and a map or keyword list. Got: collection=#{inspect(other)}, data=#{inspect(data)}"}

  @spec delete(Chroma.Collection.t()) :: any()
  @doc """
  Deletes a collection.

  This function supports both v1 and v2 API endpoints based on the provided
  Chroma.Collection struct.

  ## Parameters

    - **collection**: The Chroma.Collection struct representing the target collection.
      For v2, this struct must have non-empty `tenant`, `database`, and `id`.
      For v1, this struct must have a non-empty `name`.

  ## Returns

    The result of the underlying HTTP request handling, typically `nil` on success
    for the `handle_json_response!/1` helper, or raises an error on failure.

  ## Examples

      # Assuming you have a v1 or v2 collection struct
      iex> v1_collection = %Chroma.Collection{name: "v1_coll_name"}
      iex> v2_collection = %Chroma.Collection{tenant: "t", database: "d", id: "v2_coll_id"}
      iex> # Assuming handle_json_response! is defined
      iex> # Chroma.Collection.delete(v1_collection)
      # Expected to call v1 API endpoint and return nil or raise

      iex> # Chroma.Collection.delete(v2_collection)
      # Expected to call v2 API endpoint and return nil or raise

      iex> # Invalid collection struct
      iex> # Chroma.Collection.delete(%Chroma.Collection{})
      # Expected to return {:error, "Invalid Chroma.Collection struct..."}

  """

  def delete(%Chroma.Collection{tenant: tenant, database: database, id: id})
      when is_binary(tenant) and tenant != "" and
             is_binary(database) and database != "" and
             is_binary(id) and id != "" do
    url = "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}"

    url
    |> Req.delete()
    |> handle_json_response!()
  end

  def delete(%Chroma.Collection{name: name})
      when is_binary(name) and name != "" do
    url = "#{Chroma.api_url()}/collections/#{name}"

    url
    |> Req.delete()
    |> handle_json_response!()
  end

  def delete(%Chroma.Collection{} = collection),
    do:
      {:error,
       "Invalid Chroma.Collection struct provided for delete/1. Ensure collection has a non-empty name (for v1) or non-empty tenant, database, and id (for v2). Got: #{inspect(collection)}"}

  def delete(other),
    do:
      {:error,
       "Invalid first argument for delete. Expected Chroma.Collection struct, got: #{inspect(other)}"}

  @spec count(Chroma.Collection.t()) :: any()
  @doc """
  Counts the number of items in a collection.

  This function supports both v1 and v2 API endpoints based on the provided
  Chroma.Collection struct.

  ## Parameters

    - **collection**: The Chroma.Collection struct representing the target collection.
      For v2, this struct must have non-empty `tenant`, `database`, and `id`.
      For v1, this struct must have a non-empty `id`.

  ## Returns

    The count of items in the collection (typically an integer) on success,
    or `nil` or `0` on error, depending on the `handle_json_response/1` helper's
    implementation for non-2xx responses.

  ## Examples

      # Assuming you have a v1 or v2 collection struct
      iex> v1_collection = %Chroma.Collection{id: "v1_coll_id"}
      iex> v2_collection = %Chroma.Collection{tenant: "t", database: "d", id: "v2_coll_id"}
      iex> # Assuming handle_json_response is defined
      iex> # Chroma.Collection.count(v1_collection)
      # Expected to return the count (integer) or nil/0

      iex> # Chroma.Collection.count(v2_collection)
      # Expected to return the count (integer) or nil/0

      iex> # Invalid collection struct
      iex> # Chroma.Collection.count(%Chroma.Collection{})
      # Expected to return {:error, "Invalid Chroma.Collection struct..."}

  """
  def count(%Chroma.Collection{tenant: tenant, database: database, id: id})
      when is_binary(tenant) and tenant != "" and
             is_binary(database) and database != "" and
             is_binary(id) and id != "" do
    url =
      "#{Chroma.api_url()}/tenants/#{tenant}/databases/#{database}/collections/#{id}/count"

    url
    |> Req.get()
    |> handle_json_response()
  end

  def count(%Chroma.Collection{id: id})
      when is_binary(id) and id != "" do
    url = "#{Chroma.api_url()}/collections/#{id}/count"

    url
    |> Req.get()
    |> handle_json_response()
  end

  def count(%Chroma.Collection{} = collection),
    do:
      {:error,
       "Invalid Chroma.Collection struct provided for count/1. Ensure collection has a non-empty id (and tenant/database for v2). Got: #{inspect(collection)}"}

  def count(other),
    do:
      {:error,
       "Invalid first argument for count. Expected Chroma.Collection struct, got: #{inspect(other)}"}

  # --- Private Helper Functions ---

  defp handle_response_list(req_result) do
    case handle_json_response(req_result) do
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

  defp handle_json_response({:ok, %Req.Response{status: status, body: body}}) do
    case status do
      code when code in 200..299 ->
        {:ok, body}

      _ ->
        error_reason =
          if is_map(body) and Map.has_key?(body, "error"), do: body["error"], else: body

        {:error, error_reason}
    end
  end

  defp handle_json_response({:error, reason}), do: {:error, reason}

  # defp handle_json_response(other),
  #   do: {:error, "Unexpected input to handle_json_response: #{inspect(other)}"}

  defp handle_json_response!(any) do
    case handle_json_response(any) do
      {:ok, body} -> body
      {:error, reason} -> raise "Chroma API Error: #{inspect(reason)}"
    end
  end
end
