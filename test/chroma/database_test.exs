defmodule Chroma.DatabaseTest do
  use ExUnit.Case, async: false

  import Mock

  test "must return version" do
    with_mock Req, get!: fn _url -> %{body: "0.4.6"} end do
      assert Chroma.Database.version() == "0.4.6"
    end
  end

  test "must reset database" do
    with_mock Req, post: fn _url -> {:ok, %Req.Response{status: 200, body: %{}}} end do
      assert Chroma.Database.reset() == {:ok, %{}}
    end
  end

  test "must persist database" do
    with_mock Req, post: fn _url -> {:ok, %Req.Response{status: 200, body: %{}}} end do
      assert Chroma.Database.persist() == {:ok, %{}}
    end
  end

  test "must return heartbeat" do
    with_mock Req,
      get: fn _url ->
        {:ok,
         %Req.Response{status: 200, body: %{"nanosecond heartbeat" => 1_692_462_594_114_306_376}}}
      end do
      assert Chroma.Database.heartbeat() ==
               {:ok, %{"nanosecond heartbeat" => 1_692_462_594_114_306_376}}
    end
  end
end
