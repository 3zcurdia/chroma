defmodule Chroma.Collection do
  @moduledoc """
  Chroma Collection methods.
  """
  defstruct id: nil, name: nil, metadata: nil

  @doc """
  Creates a new `Chroma.Collection` struct.

  Examples:

      iex> Chroma.Collection.new(%{"id" => "123", "name" => "my_collection", "metadata" => %{}})
      %Chroma.Collection{id: "123", name: "my_collection", metadata: %{}}
  """
  @spec new(map) :: %Chroma.Collection{id: any, metadata: any, name: any}
  def new(%{"id" => id, "name" => name, "metadata" => metadata}) do
    %Chroma.Collection{id: id, name: name, metadata: metadata}
  end

  @doc """
  Lists all collections.
  """
  @spec list :: {:error, any} | {:ok, list}
  def list do
    "#{Chroma.api_url()}/collections"
    |> Req.get()
    |> handle_response_list()
  end

  @doc """
  Gets a collection by name.
  """
  @spec get(any) :: {:error, any} | {:ok, %Chroma.Collection{id: any, metadata: any, name: any}}
  def get(name) do
    "#{Chroma.api_url()}/collections/#{name}"
    |> Req.get()
    |> handle_response()
  end

  @doc """
  Creates a collection.
  """
  @spec create(String.t(), map()) ::
          {:error, any} | {:ok, %Chroma.Collection{id: any, metadata: any, name: any}}
  def create(name, metadata \\ %{}) do
    json = %{name: name, metadata: metadata, get_or_create: false}

    "#{Chroma.api_url()}/collections"
    |> Req.post(json: json)
    |> handle_response()
  end

  @doc """
  Gets or create a collection by name.
  """
  @spec get_or_create(String.t(), map()) ::
          {:error, any} | {:ok, %Chroma.Collection{id: any, metadata: any, name: any}}
  def get_or_create(name, metadata \\ %{}) do
    json = %{name: name, metadata: metadata, get_or_create: true}

    "#{Chroma.api_url()}/collections"
    |> Req.post(json: json)
    |> handle_response()
  end

  def update(_collection, []), do: {:error, "No embeddings provided"}

  def update(%Chroma.Collection{id: id}, embeddings) when is_list(embeddings) do
    "#{Chroma.api_url()}/collections/#{id}/update"
    |> Req.post(json: embeddings)
    |> handle_json_response()
  end

  def upsert(_collection, []), do: {:error, "No embeddings provided"}

  def upsert(%Chroma.Collection{id: id}, embeddings) when is_list(embeddings) do
    "#{Chroma.api_url()}/collections/#{id}/upsert"
    |> Req.post(json: embeddings)
    |> handle_json_response()
  end

  @doc """
  Counts all embeddings from a collection.
  """
  @spec count(%Chroma.Collection{:id => any}) :: {:error, any} | {:ok, any}
  def count(%Chroma.Collection{id: id}) do
    "#{Chroma.api_url()}/collections/#{id}/count"
    |> Req.get()
    |> handle_json_response()
  end

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

  def modify(_any_struct, _any), do: {:error, "Invalid arguments"}

  @doc """
  Creates an index for a collection.
  """
  @spec create_index(%Chroma.Collection{:id => any}) :: {:error, any} | {:ok, any}
  def create_index(%Chroma.Collection{id: id}) do
    # TODO: Review enpoint documentation
    "#{Chroma.api_url()}/collections/#{id}/create_index"
    |> Req.post()
    |> handle_json_response()
  end

  def query(%Chroma.Collection{id: id}, embeddings, options) do
    json = %{
      query_embeddings: embeddings,
      n_results: Map.get(options, :results, 10),
      where: Map.get(options, :where, %{}),
      where_document: Map.get(options, :where_document, %{}),
      include: Map.get(options, :include, ["metadatas", "documents", "distances"])
    }

    "#{Chroma.api_url()}/collections/#{id}/query"
    |> Req.post(json: json)
    |> handle_json_response()
  end

  @doc """
  Deletes a collection by name.
  """
  @spec delete(%Chroma.Collection{:name => String.t()}) :: {:error, any} | {:ok, any}
  def delete(%Chroma.Collection{name: name}) do
    "#{Chroma.api_url()}/collections/#{name}"
    |> Req.delete()
    |> handle_json_response()
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

  defp handle_json_response({:ok, %Req.Response{status: status, body: body}}) do
    case status do
      code when code in 200..299 -> {:ok, body}
      _ -> {:error, body["error"]}
    end
  end

  defp handle_json_response(any), do: any
end
