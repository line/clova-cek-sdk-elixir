defmodule Clova.SkillPlug do
  @behaviour Plug

  @moduledoc """
  This plug provides the necessary middlewear to handle a request from the Clova server, call your
  `Clova` implementation, and build the HTTP response.

  This plug is a convenience wrapper of four other plugs: `Plug.Parsers`, `Clova.ValidatorPlug`,
  `Clova.DispatcherPlug`, and `Clova.EncoderPlug`. For most skills, this plug should be sufficient, but
  for more complex skills it may be necessary to use the underlying plugs directly.

  Usage:
  ```
  plug Clova.SkillPlug,
    dispatch_to: MyExtension,
    app_id: "com.example.my_extension",
    json_module: Poison
    # (for development - see Clova.ValidatorPlug) force_signature_valid: OR public_key:
  ```

  This is equivalent to:
  ```
  plug Plug.Parsers,
    parsers: [:json],
    json_decoder: Poison,
    body_reader: Clova.CachingBodyReader.spec()
  plug Clova.ValidatorPlug, app_id: "com.example.my_extension"
  plug Clova.DispatcherPlug, dispatch_to: MyExtension
  plug Clova.EncoderPlug, json_encoder: Poison
  ```

  ## Options

  The options are handled the underlying wrapped plugs. The minimal recommended options are listed here.
  * `:dispatch_to` - Required. The name of your module that implements the `Clova` behaviour to handle clova requests.
  * `:app_id` - Optional. The application ID as specified in the Clova Developer Center. All requests must contain this ID in the request body. If this option is not provided, the app ID validity is not checked.
  * `:json_module` - The name of the module that will be used to decode and encode the JSON. Can also be in MFA format. Optional if `:json_decoder` and `:json_encoder` are provided.
  * `:json_decoder` - The name of the module that will be used to decode the JSON. Can also be in MFA format. Optional if `:json_module` is provided.
  * `:json_encoder` - The name of the module that will be used to encode the JSON. Can also be in MFA format. Optional if `:json_module` is provided.
  """

  def init(opts) do
    {
      init_parser(opts),
      init_encoder(opts),
      Clova.ValidatorPlug.init(opts),
      Clova.DispatcherPlug.init(opts)
    }
  end

  def call(conn, {opts_parser, opts_encoder, opts_validator, opts_dispatcher}) do
    with %{halted: false} = conn <- Plug.Parsers.call(conn, opts_parser),
         %{halted: false} = conn <- Clova.ValidatorPlug.call(conn, opts_validator),
         %{halted: false} = conn <- Clova.DispatcherPlug.call(conn, opts_dispatcher),
         %{halted: false} = conn <- Clova.EncoderPlug.call(conn, opts_encoder),
         do: conn
  end

  defp init_parser(opts) do
    json_decoder = Keyword.get(opts, :json_decoder) || Keyword.get(opts, :json_module)

    Plug.Parsers.init(
      parsers: [:json],
      json_decoder: json_decoder,
      body_reader: Clova.CachingBodyReader.spec()
    )
  end

  defp init_encoder(opts) do
    json_encoder = Keyword.get(opts, :json_encoder) || Keyword.get(opts, :json_module)
    Clova.EncoderPlug.init(json_encoder: json_encoder)
  end
end
