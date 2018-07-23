defmodule Clova.DispatcherTest do
  use ExUnit.Case, asunc: true
  use Plug.Test
  alias Clova.Dispatcher

  defmodule MockHandler do
    def handle_launch(_, _), do: ["handled launch request"]
    def handle_intent(intent, _, _), do: ["handled #{intent} intent request"]
    def handle_session_ended(_, _), do: ["handled session ended request"]
  end

  test "init requires dispatch_to: Module name" do
    assert %{dispatch_to: Foo} = Dispatcher.init(dispatch_to: Foo)

    assert_raise(
      ArgumentError,
      ~s/:dispatch_to option must be a module name atom, got: "foo"/,
      fn -> Dispatcher.init(dispatch_to: "foo") end
    )

    assert_raise(
      ArgumentError,
      "Must supply dispatch module as :dispatch_to argument",
      fn -> Dispatcher.init([]) end
    )
  end

  test "init defaults :skip_json_encoding to false" do
    assert %{skip_json_encoding: false} = Dispatcher.init(dispatch_to: Foo)

    assert %{skip_json_encoding: true} =
             Dispatcher.init(dispatch_to: Foo, skip_json_encoding: true)
  end

  test "relevant handler function gets called" do
    opts = %{dispatch_to: MockHandler, skip_json_encoding: false}
    launch_req = make_req("LaunchRequest")
    launch_res = Dispatcher.call(launch_req, opts)
    assert ["application/json; charset=utf-8"] == get_resp_header(launch_res, "content-type")
    assert ~s'["handled launch request"]' == launch_res.resp_body

    launch_req = make_req("IntentRequest", "foo")
    launch_res = Dispatcher.call(launch_req, opts)
    assert ["application/json; charset=utf-8"] == get_resp_header(launch_res, "content-type")
    assert ~s'["handled foo intent request"]' == launch_res.resp_body

    launch_req = make_req("SessionEndedRequest")
    launch_res = Dispatcher.call(launch_req, opts)
    assert ["application/json; charset=utf-8"] == get_resp_header(launch_res, "content-type")
    assert ~s'["handled session ended request"]' == launch_res.resp_body
  end

  test "skip json flag skips json encoding and sets response code" do
    opts = %{dispatch_to: MockHandler, skip_json_encoding: true}
    launch_req = make_req("LaunchRequest")
    launch_res = Dispatcher.call(launch_req, opts)
    assert "JSON encoding skipped" == launch_res.resp_body
    assert ["handled launch request"] == launch_res.assigns.clova_response
    assert launch_res.status == 200

    bad_req = put_status(launch_req, :forbidden)
    launch_res = Dispatcher.call(bad_req, opts)
    assert "JSON encoding skipped" == launch_res.resp_body
    assert ["handled launch request"] == launch_res.assigns.clova_response
    assert launch_res.status == 403
  end

  defp make_req(type, intent \\ nil) do
    req = %Clova.Request{}
    req = put_in(req.request.type, type)
    req = put_in(req.request.intent.name, intent)
    conn = conn(:post, "/clova", "")
    put_in(conn.body_params, req)
  end
end
