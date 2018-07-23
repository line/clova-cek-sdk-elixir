defmodule Clova.RequestTest do
  use ExUnit.Case
  alias Clova.Request

  test "get_slot returns nil if there is no slot data" do
    request = make_request(nil)
    slots = Request.get_slot(request, "foo")
    assert slots == nil
  end

  test "get_slot returns nil slot is present but its value is nil" do
    request = make_request(%{"foo" => %{"name" => "foo", "value" => nil}})
    slots = Request.get_slot(request, "foo")
    assert slots == nil
  end

  test "get_slot returns the value of the slot data" do
    request = make_request(%{"foo" => %{"name" => "foo", "value" => "bar"}})
    slots = Request.get_slot(request, "foo")
    assert slots == "bar"
  end

  defp make_request(slots) do
    %Request{request: %Request.Request{intent: %Request.Intent{slots: slots}}}
  end
end
