defmodule Chroma.Collection do
  @moduledoc """
  It intereacts with the collection basic operations.
  """
  defstruct id: nil, name: nil, metadata: nil
  @type t :: %__MODULE__{id: String.t(), name: String.t(), metadata: map()}

  @doc """
  It allows to query the database for similar embeddings.

  ## Parameters

    - **query_embeddings**: A list of embeddings to query.
    - **results**: The number of results to return.
    - **where**: A map of metadata fields to filter by.
    - **where_document**: A map of document fields to filter by.

  ## Examples

      iex> Chroma.Collection.query(
        %Chroma.Collection{id: "123"},
        query_embeddings: [[11.1, 12.1, 13.1],[1.1, 2.3, 3.2], ...],
        where: %{"metadata_field": "is_equal_to_this"},
        where_document: %{"$contains" => "search_string"}
      )
      {:ok, [%Chroma.Embedding{embedding: [1, 2, 3], id: "123", metadata: %{}}]}
  """
  def query(%Chroma.Collection{id: id}, kargs) do
    options =
      kargs
      |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, key, value) end)

    json =
      %{
        query_embeddings: Map.get(options, :query_embeddings, []),
        n_results: Map.get(options, :results, 10),
        where: Map.get(options, :where, %{}),
        where_document: Map.get(options, :where_document, %{}),
        include: Map.get(options, :include, ["metadatas", "documents", "distances"])
      }
      |> Map.filter(fn {_, v} -> v != nil end)

    "#{Chroma.api_url()}/collections/#{id}/query"
    |> Req.post(json: json)
    |> handle_json_response()
  end

  @doc """
  Creates a new `Chroma.Collection` struct.

  ## Examples

      iex> Chroma.Collection.new(%{"id" => "123", "name" => "my_collection", "metadata" => %{}})
      %Chroma.Collection{id: "123", name: "my_collection", metadata: %{}}
  """
  @spec new(map) :: %{id: any, metadata: any, name: any}
  def new(%{"id" => id, "name" => name, "metadata" => metadata}) do
    %Chroma.Collection{id: id, name: name, metadata: metadata}
  end

  @doc """
  Lists all collections.

  ## Examples

      iex> Chroma.Collection.list()
      {:ok, [%Chroma.Collection{id: "123", name: "my_collection", metadata: %{}}]}
  """
  @spec list :: {:error, any} | {:ok, list}
  def list do
    "#{Chroma.api_url()}/collections"
    |> Req.get()
    |> handle_response_list()
  end

  @doc """
  Gets a collection by name.

  ## Examples

      iex> Chroma.Collection.get("my_collection")
      {:ok, %Chroma.Collection{id: "123", name: "my_collection", metadata: %{}}}
  """
  @spec get(any) :: {:error, any} | {:ok, %{id: any, metadata: any, name: any}}
  def get(name) do
    "#{Chroma.api_url()}/collections/#{name}"
    |> Req.get()
    |> handle_response()
  end

  @doc """
  Gets a collection by name.

  ## Examples

      iex> Chroma.Collection.get!("my_collection")
      %Chroma.Collection{id: "123", name: "my_collection", metadata: %{}}
  """
  @spec get!(any) :: %{id: any, metadata: any, name: any}
  def get!(name) do
    name
    |> get()
    |> handle_response!()
  end

  @doc """
  Creates a collection.

  ## Examples

      iex> Chroma.Collection.create("my_collection", metadata: %{type: "test"})
      {:ok, %Chroma.Collection{id: "123", name: "my_collection", metadata: %{type: "test"}}}
  """
  @spec create(String.t(), map()) :: {:error, any} | {:ok, %{id: any, metadata: any, name: any}}
  def create(name, metadata \\ %{}) do
    json = %{name: name, metadata: metadata, get_or_create: false}

    "#{Chroma.api_url()}/collections"
    |> Req.post(json: json)
    |> handle_response()
  end

  @doc """
  Creates a collection.

  ## Examples

      iex> Chroma.Collection.create!("my_collection", metadata: %{type: "test"})
      %Chroma.Collection{id: "123", name: "my_collection", metadata: %{type: "test"}}
  """
  @spec create!(binary, map) :: %{id: any, metadata: any, name: any}
  def create!(name, metadata \\ %{}) do
    name
    |> create(metadata)
    |> handle_response!()
  end

  @doc """
  Gets or create a collection by name.

  ## Examples

      iex> Chroma.Collection.get_or_create("my_collection", metadata: %{type: "test"})
      {:ok, %Chroma.Collection{id: "123", name: "my_collection", metadata: %{type: "test"})}}
  """
  @spec get_or_create(String.t(), map()) ::
          {:error, any} | {:ok, %{id: any, metadata: any, name: any}}
  def get_or_create(name, metadata \\ %{}) do
    json = %{name: name, metadata: metadata, get_or_create: true}

    "#{Chroma.api_url()}/collections"
    |> Req.post(json: json)
    |> handle_response()
  end

  @doc """
  Gets or create a collection by name.

  ## Examples

      iex> Chroma.Collection.get_or_create!("my_collection", metadata: %{type: "test"})
      %Chroma.Collection{id: "123", name: "my_collection", metadata: %{type: "test"}}
  """
  @spec get_or_create!(binary, map) :: %{id: any, metadata: any, name: any}
  def get_or_create!(name, metadata \\ %{}) do
    name
    |> get_or_create(metadata)
    |> handle_response!()
  end

  @doc """
  Adds a batch of embeddings in the database.
  """
  @spec add(%{:id => any}, map) :: {:error, any} | {:ok, any}
  def add(%Chroma.Collection{id: id}, %{} = data) do
    "#{Chroma.api_url()}/collections/#{id}/add"
    |> Req.post(json: data)
    |> handle_json_response!()
  end

  @doc """
  Updates a batch of embeddings in the database.
  """
  def update(%Chroma.Collection{id: id}, %{} = data) do
    "#{Chroma.api_url()}/collections/#{id}/update"
    |> Req.post(json: data)
    |> handle_json_response()
  end

  @doc """
  Upserts a batch of embeddings in the database
  """
  @spec upsert(%{:id => any}, %{:embeddings => map}) :: {:error, any} | {:ok, any}
  def upsert(%Chroma.Collection{id: id}, %{embeddings: _embeddings} = data) do
    "#{Chroma.api_url()}/collections/#{id}/upsert"
    |> Req.post(json: data)
    |> handle_json_response()
  end

  @doc """
  It updates the name and metadata of a collection.

  ## Examples

      iex> Chroma.Collection.modify(%Chroma.Collection{id: "123"}, name: "new_name")
      {:ok, %Chroma.Collection{id: "123", name: "new_name", metadata: %{}}}

      iex> Chroma.Collection.modify(%Chroma.Collection{id: "123"}, metadata: %{type: "test"})
      {:ok, %Chroma.Collection{id: "123", name: "new_name", metadata: %{type: "test"}}}

      iex> Chroma.Collection.modify(%Chroma.Collection{id: "123"}, %{name: "new_name", metadata: %{type: "test"}})
      {:ok, %Chroma.Collection{id: "123", name: "new_name", metadata: %{type: "test"}}}
  """
  def modify(%Chroma.Collection{} = collection, kwargs) when is_list(kwargs) do
    args =
      kwargs
      |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, key, value) end)

    modify(collection, args)
  end

  @spec modify(%{:id => any}, %{:name => String.t(), :metatada => map}) ::
          {:error, any} | {:ok, any}
  def modify(%Chroma.Collection{id: id}, args) when is_map(args) do
    json =
      %{new_name: args[:name], new_metadata: args[:metadata]}
      |> Map.filter(fn {_, v} -> v != nil && v != %{} && v != [] end)

    "#{Chroma.api_url()}/collections/#{id}"
    |> Req.put(json: json)
    |> handle_json_response()
  end

  @doc """
  Deletes a collection by name.

  ## Examples

      iex> Chroma.Collection.delete("my_collection")
      nil
  """
  @spec delete(%{:name => String.t()}) :: any
  def delete(%Chroma.Collection{name: name}) do
    "#{Chroma.api_url()}/collections/#{name}"
    |> Req.delete()
    |> handle_json_response!()
  end

  @doc """
  Counts all embeddings from a collection.

  ## Examples

      iex> Chroma.Collection.count(%Chroma.Collection{id: "123"})
      100
  """
  @spec count(%{:id => any}) :: any
  def count(%Chroma.Collection{id: id}) do
    case Req.get("#{Chroma.api_url()}/collections/#{id}/count") do
      {:ok, %Req.Response{status: status, body: body}} ->
        case status do
          code when code in 200..299 -> body
          _ -> 0
        end

      {:error, _response} ->
        nil
    end
  end

  defp handle_response_list(response) do
    case handle_json_response(response) do
      {:ok, body} -> {:ok, Enum.map(body, &Chroma.Collection.new/1)}
      any -> any
    end
  end

  defp handle_response(response) do
    case handle_json_response(response) do
      {:ok, body} -> {:ok, Chroma.Collection.new(body)}
      any -> any
    end
  end

  defp handle_response!(response) do
    case handle_response(response) do
      {:ok, body} -> body
      {:error, body} -> raise body
    end
  end

  defp handle_json_response({:ok, %Req.Response{status: status, body: body}}) do
    case status do
      code when code in 200..299 -> {:ok, body}
      _ -> {:error, body["error"]}
    end
  end

  defp handle_json_response(any), do: any

  defp handle_json_response!(any) do
    case handle_json_response(any) do
      {:ok, body} -> body
      {:error, body} -> raise body
    end
  end
end
