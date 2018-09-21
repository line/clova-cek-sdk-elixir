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

  test "get_session_attributes gets the session attributes" do
    assert make_request() |> Request.get_session_attributes() === %{"foo" => "bar"}
  end

  test "get_application id gets the application do" do
    assert make_request() |> Request.get_application_id() === "test_app_id"
  end

  defp make_request(slots \\ nil) do
    %{
      "request" => %{"intent" => %{"slots" => slots}},
      "session" => %{"sessionAttributes" => %{"foo" => "bar"}},
      "context" => %{"System" => %{"application" => %{"applicationId" => "test_app_id"}}}
    }
  end
end
