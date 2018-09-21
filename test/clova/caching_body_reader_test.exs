defmodule Clova.CachingBodyReaderTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @known_json ~S({"foo":"bar"})

  defmodule MockJsonDecoder do
    def decode!(_), do: %{"foo" => "bar"}
  end

  test "Requesting full body returns it and sets :raw_body" do
    {state, content, conn} = Clova.CachingBodyReader.read_body(make_conn(), [])
    assert state === :ok
    assert content === @known_json
    assert conn.assigns.raw_body === @known_json
  end

  test "Requesting a part of the data returns :more with that much data and sets :raw_body" do
    {state, content, conn} = Clova.CachingBodyReader.read_body(make_conn(), length: 3)
    assert state === :more
    assert content === ~S({"f)
    assert conn.assigns.raw_body === ~S({"f)
  end

  test "Requesting the next part of the data returns :more and that data, and updates :raw_body" do
    {_state, _content, conn} = Clova.CachingBodyReader.read_body(make_conn(), length: 3)
    {state, content, conn} = Clova.CachingBodyReader.read_body(conn, length: 3)
    assert state === :more
    assert content === ~S(oo")
    assert conn.assigns.raw_body === ~S({"foo")
  end

  test "Requesting the final part of the data returns :ok and that data, and updates :raw_body" do
    {_state, _content, conn} = Clova.CachingBodyReader.read_body(make_conn(), length: 3)
    {state, content, conn} = Clova.CachingBodyReader.read_body(conn, length: 20)
    assert state === :ok
    assert content === ~S(oo":"bar"})
    assert conn.assigns.raw_body === @known_json
  end

  test "Works as argument to Plug.Parsers" do
    opts =
      Plug.Parsers.init(
        parsers: [:json],
        json_decoder: MockJsonDecoder,
        body_reader: Clova.CachingBodyReader.spec()
      )

    conn = make_conn() |> Plug.Parsers.call(opts)
    assert conn.assigns.raw_body === @known_json
    assert conn.body_params === %{"foo" => "bar"}
  end

  def make_conn do
    Plug.Test.conn(:post, "/", @known_json)
    |> Plug.Conn.put_req_header("content-type", "application/json")
  end
end
