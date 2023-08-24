# Chroma

A [ChromaDB](https://trychroma.com) client for Elixir.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `chroma` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chroma, "~> 0.1.2"}
  ]
end
```

## Configuration

In your config file you can setup the following:

```elixir
config :chroma, 
  host: "http://localhost:8000",
  api_base: "api",
  api_version: "v1"
```

By default the config is set to `api/v1`

## Usage

To verify that the client is connected to the server, you can use the `version` function from the `Chroma.Database` module:

```elixir
Chroma.Database.version
```

To handle all collection actions, you can use the `Chroma.Collection` module:

```elixir
  {:ok, collection} = Chroma.Collection.create("my_collection", %{name: "string", age: "int"})
  {:ok, collection} = Chroma.Collection.get_or_create("my_collection", %{name: "string", age: "int"})
  {:ok, collection} = Chroma.Collection.get("my_collection")
  Chroma.Collection.delete("my_collection")
```

The client does not generate embeddings, but you can generate embeddings using [bumblebee](https://github.com/elixir-nx/bumblebee) with the [TextEmbedding module](https://hexdocs.pm/bumblebee/Bumblebee.Text.html#text_embedding/3-examples), you can find an example on this [livebook](https://github.com/3zcurdia/chroma/tree/main/livebooks/text-embedding.livemd).

Once you get the embeddings for your documents, you can index them using the `add` function from the `Chroma.Collection` module:

```elixir
  {:ok, collection} = Chroma.Collection.get_or_create("my_collection", %{type: "Text"})
  Chroma.Collection.add(collection, 
    %{
      embeddings: embeddings,
      documents: documents,
      metadata: metadata,
      ids: ids
    }
  )
```

This will add the documents, embeddings and metadata to the collection. Now you can query using a query embeddings list:

```elixir
  Chroma.Collection.query(collection, 
    %{
      embeddings: query_embeddings,
        query_embeddings: query_embeddings,
        where: %{"metadata_field": "is_equal_to_this"},
        where_document: %{"$contains" => "search_string"}
    }
  )
```

To understand better how to query, you can check the [ChromaDB usage guide](https://docs.trychroma.com/usage-guide). You can also check the [livebook](https://github.com/3zcurdia/chroma/tree/main/livebooks/chroma-example.livemd) where you can find a full example of how to use the client.

## License

Chroma is released under the [MIT License](https://opensource.org/licenses/MIT).
