# Chroma

A [ChromaDB](https://trychroma.com) client for Elixir.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `chroma` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chroma, "~> 0.1.0"}
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
  {:ok, collection } = Chroma.Collection.create("my_collection", %{name: "string", age: "int"})
  {:ok, collection } = Chroma.Collection.get_or_create("my_collection", %{name: "string", age: "int"})
  {:ok, collection } = Chroma.Collection.get("my_collection")
  Chroma.Collection.delete("my_collection")
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/chroma>.

