defmodule Clova.Request do
  @moduledoc """
  Helpers to extract data from the Clova request.
  """

  @doc """
  Helper function to retrieve the data of a named slot from a clova request. Returns
  the retrieved data, or `nil` if not present.
  """
  def get_slot(%{"request" => %{"intent" => %{"slots" => slots}}}, slot_name) do
    slots[slot_name]["value"]
  end

  @doc """
  Helper function to retrieve the session attributes.
  """
  def get_session_attributes(%{"session" => %{"sessionAttributes" => sessionAttributes}}) do
    sessionAttributes
  end

  @doc """
  Helper function to retrieve the application ID.
  """
  def get_application_id(%{
        "context" => %{"System" => %{"application" => %{"applicationId" => app_id}}}
      }) do
    app_id
  end
end
