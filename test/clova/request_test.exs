defmodule Clova.RequestTest do
  use ExUnit.Case
  alias Clova.Request

  test "get_slot returns nil if there is no slot data" do
    request = make_request(slots: nil)
    slots = Request.get_slot(request, "foo")
    assert slots == nil
  end

  test "get_slot returns nil slot is present but its value is nil" do
    request = make_request(slots: %{"foo" => %{"name" => "foo", "value" => nil}})
    slots = Request.get_slot(request, "foo")
    assert slots == nil
  end

  test "get_slot returns the value of the slot data" do
    request = make_request(slots: %{"foo" => %{"name" => "foo", "value" => "bar"}})
    slots = Request.get_slot(request, "foo")
    assert slots == "bar"
  end

  test "get_session_attributes gets the session attributes" do
    empty_req = %Request{}
    assert empty_req.session.sessionAttributes === %{}
    assert Request.get_session_attributes(empty_req) === %{}

    attrib_req = make_request(session_attrs: %{foo: "bar"})
    assert attrib_req.session.sessionAttributes === %{foo: "bar"}
    assert Request.get_session_attributes(attrib_req) === %{foo: "bar"}

  end

  defp make_request(slots: slots) do
    %Request{request: %Request.Request{intent: %Request.Intent{slots: slots}}}
  end

  defp make_request(session_attrs: session_attrs) do
    %Request{session: %Request.Session{sessionAttributes: session_attrs}}
  end
end
