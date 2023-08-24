defmodule Chroma.Collection do
  @moduledoc """
  Basic operations to intereact with collections.
  """
  defstruct id: nil, name: nil, metadata: nil
  @type t :: %__MODULE__{id: String.t(), name: String.t(), metadata: map()}

  @spec query(Chroma.Collection.t(), list()) :: {:error, any} | {:ok, any}
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

  @spec new(map) :: Chroma.Collection.t()
  @doc """
  Creates a new `Chroma.Collection` struct.

  ## Examples

      iex> Chroma.Collection.new(%{"id" => "123", "name" => "my_collection", "metadata" => %{}})
      %Chroma.Collection{id: "123", name: "my_collection", metadata: %{}}
  """
  def new(%{"id" => id, "name" => name, "metadata" => metadata}) do
    %Chroma.Collection{id: id, name: name, metadata: metadata}
  end

  @spec list :: {:error, any} | {:ok, list(Chroma.Collection.t())}
  @doc """
  Lists all stored collections in the database.

  ## Examples

      iex> Chroma.Collection.list()
      {:ok, [%Chroma.Collection{id: "123", name: "my_collection", metadata: %{}}]}
  """
  def list do
    "#{Chroma.api_url()}/collections"
    |> Req.get()
    |> handle_response_list()
  end

  @spec get(String.t()) :: {:error, any} | {:ok, Chroma.Collection.t()}
  @doc """
  Gets a collection by name.

  ## Examples

      iex> Chroma.Collection.get("my_collection")
      {:ok, %Chroma.Collection{id: "123", name: "my_collection", metadata: %{}}}
  """
  def get(name) do
    "#{Chroma.api_url()}/collections/#{name}"
    |> Req.get()
    |> handle_response()
  end

  @spec get!(String.t()) :: Chroma.Collection.t()
  @doc """
  Gets a collection by name.

  ## Examples

      iex> Chroma.Collection.get!("my_collection")
      %Chroma.Collection{id: "123", name: "my_collection", metadata: %{}}
  """
  def get!(name) do
    name
    |> get()
    |> handle_response!()
  end

  @spec create(String.t(), map()) :: {:error, any} | {:ok, Chroma.Collection.t()}
  @doc """
  Creates a collection.

  ## Examples

      iex> Chroma.Collection.create("my_collection", metadata: %{type: "test"})
      {:ok, %Chroma.Collection{id: "123", name: "my_collection", metadata: %{type: "test"}}}
  """
  def create(name, metadata \\ %{}) do
    json = %{name: name, metadata: metadata, get_or_create: false}

    "#{Chroma.api_url()}/collections"
    |> Req.post(json: json)
    |> handle_response()
  end

  @spec create!(binary, map) :: Chroma.Collection.t()
  @doc """
  Creates a collection.

  ## Examples

      iex> Chroma.Collection.create!("my_collection", metadata: %{type: "test"})
      %Chroma.Collection{id: "123", name: "my_collection", metadata: %{type: "test"}}
  """
  def create!(name, metadata \\ %{}) do
    name
    |> create(metadata)
    |> handle_response!()
  end

  @spec get_or_create(String.t(), map()) :: {:error, any} | {:ok, Chroma.Collection.t()}
  @doc """
  Gets or create a collection by name.

  ## Examples

      iex> Chroma.Collection.get_or_create("my_collection", metadata: %{type: "test"})
      {:ok, %Chroma.Collection{id: "123", name: "my_collection", metadata: %{type: "test"})}}
  """
  def get_or_create(name, metadata \\ %{}) do
    json = %{name: name, metadata: metadata, get_or_create: true}

    "#{Chroma.api_url()}/collections"
    |> Req.post(json: json)
    |> handle_response()
  end

  @spec get_or_create!(String.t(), map) :: Chroma.Collection.t()
  @doc """
  Gets or create a collection by name.

  ## Examples

      iex> Chroma.Collection.get_or_create!("my_collection", metadata: %{type: "test"})
      %Chroma.Collection{id: "123", name: "my_collection", metadata: %{type: "test"}}
  """
  def get_or_create!(name, metadata \\ %{}) do
    name
    |> get_or_create(metadata)
    |> handle_response!()
  end

  @spec add(Chroma.Collection.t(), map) :: any
  @doc """
  Adds a batch of embeddings in the database.

  ## Examples

        iex> Chroma.Collection.add(%Chroma.Collection{id: "123"}, %{embeddings: [[1, 2, 3], [4, 5, 6]]})
        nil

        iex> Chroma.Collection.add(%Chroma.Collection{id: "123",{ documents: documents, embeddings: embeddings, metadata: metadata, ids: pages})
        nil
  """
  def add(%Chroma.Collection{id: id}, %{} = data) do
    "#{Chroma.api_url()}/collections/#{id}/add"
    |> Req.post(json: data)
    |> handle_json_response!()
  end

  @spec update(Chroma.Collection.t(), map) :: {:error, any} | {:ok, any}
  @doc """
  Updates a batch of embeddings in the database.
  """
  def update(%Chroma.Collection{id: id}, %{} = data) do
    "#{Chroma.api_url()}/collections/#{id}/update"
    |> Req.post(json: data)
    |> handle_json_response()
  end

  @spec upsert(Chroma.Collection.t(), map) :: {:error, any} | {:ok, any}
  @doc """
  Upserts a batch of embeddings in the database
  """
  def upsert(%Chroma.Collection{id: id}, data) do
    "#{Chroma.api_url()}/collections/#{id}/upsert"
    |> Req.post(json: data)
    |> handle_json_response()
  end

  @spec modify(Chroma.Collection.t(), maybe_improper_list | map) :: {:error, any} | {:ok, any}
  @doc """
  It updates the name and metadata of a collection.

  ## Parameters

    - **name**: The new name of the collection.
    - **metadata**: The new metadata of the collection.

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

  def modify(%Chroma.Collection{id: id}, args) when is_map(args) do
    json =
      %{new_name: args[:name], new_metadata: args[:metadata]}
      |> Map.filter(fn {_, v} -> v != nil && v != %{} && v != [] end)

    "#{Chroma.api_url()}/collections/#{id}"
    |> Req.put(json: json)
    |> handle_json_response()
  end

  @spec delete(Chroma.Collection.t()) :: any
  @doc """
  Deletes a collection by name.

  ## Examples

      iex> Chroma.Collection.delete("my_collection")
      nil
  """
  def delete(%Chroma.Collection{name: name}) do
    "#{Chroma.api_url()}/collections/#{name}"
    |> Req.delete()
    |> handle_json_response!()
  end

  @spec count(Chroma.Collection.t()) :: any
  @doc """
  Counts all embeddings from a collection.

  ## Examples

      iex> Chroma.Collection.count(%Chroma.Collection{id: "123"})
      100
  """
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
