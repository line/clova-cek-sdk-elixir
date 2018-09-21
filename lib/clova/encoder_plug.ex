defmodule Clova.EncoderPlug do
  import Plug.Conn
  @behaviour Plug

  @moduledoc """
  Encodes the data contained in the `:clova_response` assign to JSON, sets it as the response body,
  and sets the content-type header. The response status is also set to `200` if it has not already been set.
  This means your endpoint can simply call `Plug.Conn.send_resp/1` with the `conn` argument.

  ```
  plug Plug.Parsers,
    parsers: [:json],
    json_decoder: Poison,
    body_reader: Clova.CachingBodyReader.spec()
  plug Clova.ValidatorPlug, app_id: "com.example.my_extension"
  plug Clova.DispatcherPlug, dispatch_to: MyExtension
  plug Clova.EncoderPlug, json_encoder: Poison

  plug :match
  plug :dispatch

  post "/endpoint" do
    send_resp(conn)
  end
  ```
  """

  def init(opts) do
    unless Keyword.get(opts, :json_encoder) do
      raise ArgumentError, "#{__MODULE__} expects a :json_encoder option"
    end

    Enum.into(opts, %{})
  end

  def call(%Plug.Conn{assigns: %{clova_response: response}} = conn, %{json_encoder: encoder}) do
    conn
    |> put_resp_content_type("application/json")
    |> resp(conn.status || :ok, encode(response, encoder))
  end

  # Use the same logic as Plug.Parsers.JSON
  defp encode(body, encoder) when is_atom(encoder) do
    encoder.encode!(body)
  end

  defp encode(body, {module, function, args}) do
    apply(module, function, [body | args])
  end
end
