defmodule Clova.Dispatcher do
  import Plug.Conn
  @behaviour Plug

  @moduledoc """
  A plug for dispatching CEK request to your `Clova` implementation.

  Pass your callback module as the `dispatch_to` argument to the plug.

  This plug expects the request to have been parsed by `Plug.Parsers`, and validated by `Clova.Validator`.

  This plug encodes the callback response into JSON and places it into the connection's response body.
  This plug also sets the connection status, meaning your endpoint can simply call `Plug.Conn.send_resp/1`
  with the `conn` argument.

  ```
  plug Plug.Parsers,
    parsers: [:json],
    json_decoder: Poison,
    body_reader: Clova.CachingBodyReader.spec()
  plug Clova.Validator, app_id: "com.example.my_extension"
  plug Clova.Dispatcher, dispatch_to: MyExtension
  plug :match
  plug :dispatch

  post "/endpoint" do
    send_resp(conn)
  end
  ```

  If you wish to disable the JSON encoding, the `skip_json_encoding` option is available.
  When skipping JSON encoding, the `Clova.Response` struct returned from your `Clova`
  implementation is placed into the `:clova_response` assign. In this case you need to set the
  `Plug.Conn`'s response body yourself.

  ```
  plug Plug.Parsers,
    parsers: [:json],
    json_decoder: Poison,
    body_reader: Clova.CachingBodyReader.spec()
  plug Clova.Validator, app_id: "com.example.my_extension"
  plug Clova.Dispatcher, dispatch_to: MyExtension, skip_json_encoding: true
  plug :match
  plug :dispatch

  post "/endpoint" do
    conn
      |> put_resp_content_type("application/json")
      |> send_resp(conn.status, Poison.encode!(conn.assigns.clova_response))
  end
  ```

  """

  def init(opts) do
    with {:ok, module} when is_atom(module) <- Keyword.fetch(opts, :dispatch_to) do
      opts
      |> Keyword.put_new(:skip_json_encoding, false)
      |> Enum.into(%{})
    else
      {:ok, module} ->
        raise ArgumentError,
          message: ":dispatch_to option must be a module name atom, got: #{inspect(module)}"

      :error ->
        raise ArgumentError, message: "Must supply dispatch module as :dispatch_to argument"
    end
  end

  def call(
        %Plug.Conn{body_params: request} = conn,
        %{dispatch_to: handler, skip_json_encoding: skip_json_encoding}
      ) do
    response =
      case request["request"]["type"] do
        "LaunchRequest" ->
          handler.handle_launch(request, %Clova.Response{})

        "IntentRequest" ->
          handler.handle_intent(request["request"]["intent"]["name"], request, %Clova.Response{})

        "SessionEndedRequest" ->
          handler.handle_session_ended(request, %Clova.Response{})
      end

    if skip_json_encoding do
      conn
      |> assign(:clova_response, response)
      |> resp(conn.status || :ok, "JSON encoding skipped")
    else
      conn
      |> put_resp_content_type("application/json")
      |> resp(:ok, Poison.encode!(response))
    end
  end
end
