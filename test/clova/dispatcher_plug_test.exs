defmodule Clova.DispatcherPlugTest do
  use ExUnit.Case, asunc: true
  use Plug.Test
  alias Clova.DispatcherPlug

  defmodule MockHandler do
    def handle_launch(_, _), do: ["handled launch request"]
    def handle_intent(intent, _, _), do: ["handled #{intent} intent request"]
    def handle_session_ended(_, _), do: ["handled session ended request"]
  end

  setup do
    %{dispatch_to: MockHandler}
  end

  test "init requires dispatch_to: Module name" do
    assert %{dispatch_to: Foo} = DispatcherPlug.init(dispatch_to: Foo)

    assert_raise(
      ArgumentError,
      ~s/:dispatch_to option must be a module name atom, got: "foo"/,
      fn -> DispatcherPlug.init(dispatch_to: "foo") end
    )

    assert_raise(
      ArgumentError,
      "Must supply dispatch module as :dispatch_to argument",
      fn -> DispatcherPlug.init([]) end
    )
  end

  test "handler_function puts response in :clova_response assign", opts do
    launch_req = make_req("LaunchRequest")
    launch_res = DispatcherPlug.call(launch_req, opts)
    assert ["handled launch request"] == launch_res.assigns.clova_response

    launch_req = make_req("IntentRequest", "foo")
    launch_res = DispatcherPlug.call(launch_req, opts)
    assert ["handled foo intent request"] == launch_res.assigns.clova_response

    launch_req = make_req("SessionEndedRequest")
    launch_res = DispatcherPlug.call(launch_req, opts)
    assert ["handled session ended request"] == launch_res.assigns.clova_response
  end

  test "Uses existing return status or sets status to 200", opts do
    launch_req = make_req("LaunchRequest")
    launch_res = DispatcherPlug.call(launch_req, opts)
    assert 200 == launch_res.status

    launch_req = make_req("LaunchRequest") |> put_status(404)
    launch_res = DispatcherPlug.call(launch_req, opts)
    assert 404 == launch_res.status
  end

  test "Puts helpful message about encoding :clova_response in response body", opts do
    launch_req = make_req("LaunchRequest")
    launch_res = DispatcherPlug.call(launch_req, opts)

    assert "Clova.Dispatcher: response placed in :clova_response Plug.Conn assign. Encode response to JSON before sending (see Clova.Encoder plug)." ==
             launch_res.resp_body
  end

  defp make_req(type, intent \\ nil) do
    req = %{"request" => %{"type" => type, "intent" => %{"name" => intent}}}
    %{conn(:post, "/clova", "") | body_params: req}
  end
end
