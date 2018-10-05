defmodule Clova.DispatcherPlug do
  import Plug.Conn
  @behaviour Plug

  @moduledoc """
  A plug for dispatching CEK request to your `Clova` implementation.

  For simple skills, `Clova.SkillPlug` provides a wrapper of this and related plugs.

  Pass your callback module as the `dispatch_to` argument to the plug.

  This plug expects the request to have been parsed by `Plug.Parsers`, and validated by `Clova.ValidatorPlug`.

  The `Clova.Response` struct returned from your `Clova` implementation is placed into the `:clova_response`
  assign. To encode it to JSON, the `Clova.EncoderPlug` can be used.

  If you do not use `Clova.EncoderPlug`, you need to encode and set the `Plug.Conn`'s response body yourself:

  ```
  plug Plug.Parsers,
    parsers: [:json],
    json_decoder: Poison,
    body_reader: Clova.CachingBodyReader.spec()

  plug Clova.ValidatorPlug, app_id: "com.example.my_extension"
  plug Clova.DispatcherPlug, dispatch_to: MyExtension

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
      Enum.into(opts, %{})
    else
      {:ok, module} ->
        raise ArgumentError,
          message: ":dispatch_to option must be a module name atom, got: #{inspect module}"

      :error ->
        raise ArgumentError, message: "Must supply dispatch module as :dispatch_to argument"
    end
  end

  def call(%Plug.Conn{body_params: request} = conn, %{dispatch_to: handler}) do
    response = dispatch(request, handler)

    message =
      "Clova.Dispatcher: response placed in :clova_response Plug.Conn assign. " <>
        "Encode response to JSON before sending (see Clova.Encoder plug)."

    conn
    |> assign(:clova_response, response)
    |> resp(conn.status || :ok, message)
  end

  defp dispatch(%{"request" => %{"type" => "LaunchRequest"}} = request, handler) do
    handler.handle_launch(request, %Clova.Response{})
  end

  defp dispatch(
         %{"request" => %{"type" => "IntentRequest", "intent" => %{"name" => name}}} = request,
         handler
       ) do
    handler.handle_intent(name, request, %Clova.Response{})
  end

  defp dispatch(%{"request" => %{"type" => "SessionEndedRequest"}} = request, handler) do
    handler.handle_session_ended(request, %Clova.Response{})
  end
end
