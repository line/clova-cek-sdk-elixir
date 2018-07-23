# Clova

A behaviour, plugs, and a parser for implementing a Clova Extension.

Defines a `Clova` behaviour which can be implemented to receive callbacks to handle requests.
`Plug` should be used to parse the request, validate it, and dispatch it to the `Clova` implementation.

Example `Plug.Router` pipeline:

```
plug Plug.Parsers, parsers: [Clova.Parser]
plug Clova.Validator, app_id: "com.example.my_extension"
plug Clova.Dispatcher, dispatch_to: MyExtension
plug :match
plug :dispatch

post "/endpoint" do
  send_resp(conn)
end
```

Example `Clova` implementation for a Hello World extension:
```
defmodule MyExtension do
  use Clova

  def handle_launch(_request, response) do
    response
    |> add_speech("ハロー、ワールド！")
    |> end_session
  end
end
```
For a more detailed example, see the [AirQuality example extension](https://github.com/line/clova-cek-sdk-elixir-sample).

[Full documentation is available on HexDocs.](https://hexdocs.pm/clova/)
