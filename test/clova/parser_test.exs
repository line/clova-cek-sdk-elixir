defmodule Clova.ParserTest do
  use ExUnit.Case, async: true
  use Plug.Test

  test "init returns identity" do
    pre = [foo: "bar", a: "b"]
    post = Clova.Parser.init(pre)
    assert pre === post
  end

  test "non-json requests are skipped" do
    orig_conn =
      conn(:post, "/clova", "not json")
      |> put_req_header("content-type", "text/plain")

    {:ok, body, conn} =
      orig_conn
      |> parse(pass: ["text/plain"])
      |> read_body()

    assert conn.req_headers === [{"content-type", "text/plain"}]
    assert body === "not json"
    assert_raise(Plug.Parsers.UnsupportedMediaTypeError, fn -> parse(orig_conn) end)
  end

  test "invalid json requests produce ParseError" do
    bad_json_req = fn -> make_req("invalid json") |> parse() end
    assert_raise(Plug.Parsers.ParseError, bad_json_req)
  end

  test "parser sets Clova.Request as body_params and places raw body in :raw_body" do
    conn = make_req() |> parse()

    assert conn.body_params === %Clova.Request{}
    assert conn.assigns.raw_body === empty_req_json()
  end

  test "json is correctly decoded as Clova.Request struct" do
    {struct, json} = make_test_intent_req()
    conn = make_req(json) |> parse()
    assert conn.body_params === struct
    assert conn.assigns.raw_body === json
  end

  test "signaturecek is decoded and placed in assigns" do
    conn = make_req() |> parse()
    assert conn.assigns.signature === {:error, "Message unsigned"}

    conn = make_req() |> put_req_header("signaturecek", "hello") |> parse()
    assert conn.assigns.signature === {:error, "Signature not Base64 encoded"}

    conn = make_req() |> put_req_header("signaturecek", "aGVsbG8=") |> parse()
    assert conn.assigns.signature === {:ok, "hello"}
  end

  def make_req(contents \\ empty_req_json()) do
    conn(:post, "/clova", contents)
    |> put_req_header("content-type", "application/json")
  end

  def empty_req_json() do
    ~S({"version":"1.0","session":{"user":{"userId":null,"accessToken":null},"sessionId":null,"sessionAttributes":{},"new":false},"request":{"type":null,"intent":{"slots":null,"name":null}},"context":{"System":{"user":{"userId":null,"accessToken":null},"device":{"deviceId":null}}}})
  end

  def make_test_intent_req() do
    intent = %Clova.Request.Intent{
      name: "test",
      slots: %{"test" => %{"name" => "test", "value" => "test"}}
    }

    request = %Clova.Request{request: %Clova.Request.Request{intent: intent}}

    json =
      ~S({"version":"1.0","session":{"user":{"userId":null,"accessToken":null},"sessionId":null,"sessionAttributes":{},"new":false},"request":{"type":null,"intent":{"slots":{"test":{"value":"test","name":"test"}},"name":"test"}},"context":{"System":{"user":{"userId":null,"accessToken":null},"device":{"deviceId":null}}}})

    {request, json}
  end

  def parse(conn, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:parsers, [Clova.Parser])
      |> Plug.Parsers.init()

    Plug.Parsers.call(conn, opts)
  end
end
