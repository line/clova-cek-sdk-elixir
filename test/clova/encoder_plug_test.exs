defmodule Clova.EncoderPlugTest do
  use ExUnit.Case, asunc: true
  use Plug.Test
  alias Clova.EncoderPlug

  defmodule MockJsonEncoder do
    def encode!([str]), do: ~s'["#{str}"]'
    def other(_), do: ~s'["other"]'
  end

  setup do
    %{json_encoder: MockJsonEncoder}
  end

  test "init requires json_encoder option" do
    assert %{json_encoder: Foo} = EncoderPlug.init(json_encoder: Foo)

    assert_raise(
      ArgumentError,
      "Elixir.Clova.EncoderPlug expects a :json_encoder option",
      fn -> EncoderPlug.init(json_module: "foo") end
    )

    assert_raise(
      ArgumentError,
      "Elixir.Clova.EncoderPlug expects a :json_encoder option",
      fn -> EncoderPlug.init([]) end
    )
  end

  test "Providing a module calls the encode!/1 function on that module" do
    resp = EncoderPlug.call(make_conn("response text"), %{json_encoder: MockJsonEncoder})
    assert ~s'["response text"]' === resp.resp_body
  end

  test "Providing MFA syntax calls the relevant function" do
    resp =
      EncoderPlug.call(make_conn("response text"), %{json_encoder: {MockJsonEncoder, :other, []}})

    assert ~s'["other"]' === resp.resp_body
  end

  defp make_conn(str) do
    conn(:post, "/clova", "")
    |> assign(:clova_response, [str])
  end
end
