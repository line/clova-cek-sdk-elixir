# Clova

A behaviour and related modules for implementing a Clova Extension.

## Summary

Defines a `Clova` behaviour which can be implemented to receive callbacks to handle requests.
`Plug` should be used to parse the request, validate it, and dispatch it to the `Clova` implementation.

Example `Plug.Router` pipeline:

```
plug Clova.SkillPlug,
  dispatch_to: MyExtension,
  app_id: "com.example.my_extension",
  json_module: Poison

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

## Installation

Add `:clova` to your `mix.exs` dependencies. This package assumes you will be using Plug - see the
[Plug documentation](https://hexdocs.pm/plug/) for setting up a Plug application.

```
  defp deps do
    [
      {:clova, "~> 0.5.0"},
      {:plug, "~> 1.6"},
      {:cowboy, "~> 2.2"},
      # You can use whichever JSON library you prefer
      {:poison, "~> 3.1"}
    ]
  end
```

## Online Documentation

[Full documentation is available on HexDocs.](https://hexdocs.pm/clova/)
