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
  host: "http://localhost:8000"
  api_version: "v1"
```

## Usage

To verify that the client is connected to the server, you can use the `version` function from the `Chroma.Database` module:

```elixir
Chroma.Database.version
```

To handle all collection actions, you can use the `Chroma.Collection` module:

```elixir
  collection = Chroma.Database.create_collection("my_collection", %{name: "string", age: "int"})
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/chroma>.

