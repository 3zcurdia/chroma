defmodule Chroma.CollectionTest do
  use ExUnit.Case, async: false

  import Mock

  test "must list all collections" do
    with_mock Req,
      get: fn _url ->
        {:ok,
         %Req.Response{
           status: 200,
           body: [%{"id" => "1234", "name" => "test", "metadata" => %{a: 1}}]
         }}
      end do
      assert Chroma.Collection.list() ==
               {:ok, [%Chroma.Collection{id: "1234", name: "test", metadata: %{a: 1}}]}
    end
  end
end
