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

  test "must create a new collection" do
    with_mock Req,
      post: fn _url, _body ->
        {:ok,
         %Req.Response{
           status: 200,
           body: %{"id" => "1234", "name" => "test", "metadata" => %{a: 1}}
         }}
      end do
      assert Chroma.Collection.create("test", %{a: 1}) ==
               {:ok, %Chroma.Collection{id: "1234", name: "test", metadata: %{a: 1}}}
    end
  end

  test "must handle error responses with both error and message fields" do
    with_mock Req,
      post: fn _url, _body ->
        {:ok,
         %Req.Response{
           status: 400,
           body: %{
             "error" => "InvalidArgumentError",
             "message" => "Collection expecting embedding with dimension of 24, got 2"
           }
         }}
      end do
      # Call a function that would use the API, like add
      # Using a V1 style collection for simplicity in the test as the error handling is generic
      assert_raise RuntimeError,
                   "Chroma API Error: \"InvalidArgumentError: Collection expecting embedding with dimension of 24, got 2\"",
                   fn ->
                     Chroma.Collection.add(
                       %Chroma.Collection{name: "test_collection_for_error"},
                       %{
                         embeddings: [[1.1, 2.2]],
                         ids: ["test_id"]
                       }
                     )
                   end
    end
  end
end
