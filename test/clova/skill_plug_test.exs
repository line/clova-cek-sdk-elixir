defmodule Clova.SkillPlugTest do
  use ExUnit.Case
  use Plug.Test

  defmodule MockJsonModule do
    def encode!(_), do: Clova.SkillPlugTest.expected_response()

    def decode!(_) do
      %{
        "context" => %{
          "System" => %{
            "application" => %{"applicationId" => "dummy"},
            "device" => %{
              "deviceId" => "dummy",
              "display" => %{
                "contentLayer" => %{"height" => 360, "width" => 640},
                "dpi" => 96,
                "orientation" => "landscape",
                "size" => "l100"
              }
            },
            "user" => %{"accessToken" => "dummy", "userId" => "dummy"}
          }
        },
        "request" => %{"type" => "LaunchRequest"},
        "session" => %{
          "new" => true,
          "sessionAttributes" => nil,
          "sessionId" => "dummy",
          "user" => %{"accessToken" => "dummy", "userId" => "dummy"}
        },
        "version" => "1.0"
      }
    end
  end

  defmodule MockDispatcher do
    def handle_launch(_, _), do: %Clova.Response{}
  end

  test "init initialises parser, encoder, validator, and dispatcher plugs" do
    common_opts = [
      json_decoder: MockJsonModule,
      json_encoder: MockJsonModule,
      force_signature_valid: true,
      dispatch_to: MockDispatcher
    ]

    opts_parser =
      Plug.Parsers.init(
        parsers: [:json],
        json_decoder: MockJsonModule,
        body_reader: Clova.CachingBodyReader.spec()
      )

    opts_encoder = Clova.EncoderPlug.init(json_encoder: MockJsonModule)
    opts_validator = Clova.ValidatorPlug.init(common_opts)
    opts_dispatcher = Clova.DispatcherPlug.init(common_opts)

    expected_opts = {opts_parser, opts_encoder, opts_validator, opts_dispatcher}
    assert expected_opts == Clova.SkillPlug.init(common_opts)
  end

  test "call with a valid request generates a valid response" do
    opts =
      Clova.SkillPlug.init(
        json_decoder: MockJsonModule,
        json_encoder: MockJsonModule,
        force_signature_valid: true,
        dispatch_to: MockDispatcher
      )

    conn = Clova.SkillPlug.call(make_conn(), opts)
    assert conn.resp_body == expected_response()
  end

  test "initialization errors from the wrapped plugs are propagated" do
    assert_raise(
      ArgumentError,
      "JSON parser expects a :json_decoder option",
      fn -> Clova.SkillPlug.init([]) end
    )

    assert_raise(
      ArgumentError,
      "Elixir.Clova.EncoderPlug expects a :json_encoder option",
      fn -> Clova.SkillPlug.init(json_decoder: MockJsonModule) end
    )

    assert_raise(
      ArgumentError,
      "Must supply dispatch module as :dispatch_to argument",
      fn -> Clova.SkillPlug.init(json_decoder: MockJsonModule, json_encoder: MockJsonModule) end
    )
  end

  test ":json_module argument is converted to :json_encoder and :json_decoder" do
    {parser, encoder} = extract_opts(json_module: A)
    assert parser == A
    assert encoder == A

    {parser, encoder} = extract_opts(json_module: B, json_encoder: C)
    assert parser == B
    assert encoder == C

    {parser, encoder} = extract_opts(json_module: D, json_decoder: E)
    assert parser == E
    assert encoder == D

    {parser, encoder} = extract_opts(json_encoder: F, json_decoder: G)
    assert parser == G
    assert encoder == F
  end

  defp extract_opts(input_opts) do
    {parser, encoder, _, _} = Clova.SkillPlug.init([{:dispatch_to, MockDispatcher} | input_opts])
    {[{_, {_, parser_module, _}}], _, _} = parser
    %{json_encoder: encoder_module} = encoder
    {parser_module, encoder_module}
  end

  defp make_conn do
    conn(:post, "/clova", "{}")
    |> put_req_header("content-type", "application/json")
    |> put_req_header("signaturecek", "aGVsbG8=")
  end

  def expected_response do
    ~S({"version": "1.0","sessionAttributes": {},"response": {"shouldEndSession": true,"reprompt": null,"outputSpeech": {"values": {"value": "dummy response","type": "PlainText","lang": "ja"},"type": "SimpleSpeech"},"directives": null,"card": null}})
  end
end
