defmodule Chroma.Collection do
  @moduledoc """
  Chroma Collection methods.
  """
  defstruct id: nil, name: nil, metadata: nil

  def new(%{"id" => id, "name" => name, "metadata" => metadata}) do
    %Chroma.Collection{id: id, name: name, metadata: metadata}
  end

  def list do
    "#{Chroma.api_url()}/collections"
    |> Req.get()
    |> handle_list_response()
  end

  defp handle_list_response({:ok, %Req.Response{status: status, body: body}}) do
    case status do
      code when code in 200..299 -> {:ok, Enum.map(body, &Chroma.Collection.new/1)}
      _ -> {:error, body["error"]}
    end
  end

  defp handle_list_response(any), do: any

  def get(name) do
    "#{Chroma.api_url()}/collections/#{name}"
    |> Req.get()
    |> handle_response()
  end

  def create(name, metadata \\ %{}) do
    json = %{name: name, metadata: metadata, get_or_create: false}

    "#{Chroma.api_url()}/collections"
    |> Req.post(json: json)
    |> handle_response()
  end

  def get_or_create(name, metadata \\ %{}) do
    json = %{name: name, metadata: metadata, get_or_create: true}

    "#{Chroma.api_url()}/collections"
    |> Req.post(json: json)
    |> handle_response()
  end

  def delete(%Chroma.Collection{name: name}) do
    case Req.delete("#{Chroma.api_url()}/collections/#{name}") do
      {:ok, %Req.Response{status: status, body: body}} ->
        {:ok, body}

        case status do
          code when code in 200..299 -> {:ok, body}
          _ -> {:error, body["error"]}
        end

      any ->
        any
    end
  end

  # TODO: Review enpoint documentation
  # def create_index(%Chroma.Collection{id: id}) do
  #   "#{Chroma.api_url()}/collections/#{id}/create_index"
  #   |> Req.post()
  #   # |> handle_response()
  # end

  def query(%Chroma.Collection{id: id}, embedings, options) do
    json = %{
      query_embeddings: embedings,
      n_results: Map.get(options, :results, 10),
      where: Map.get(options, :where, %{}),
      where_document: Map.get(options, :where_document, %{}),
      include: Map.get(options, :include, ["metadatas", "documents", "distances"])
    }

    "#{Chroma.api_url()}/collections/#{id}/query"
    |> Req.post(json: json)
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}}) do
    case status do
      code when code in 200..299 -> {:ok, Chroma.Collection.new(body)}
      _ -> {:error, body["error"]}
    end
  end

  defp handle_response(any), do: any
end
