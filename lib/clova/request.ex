defmodule Clova.Request.Intent do
  @moduledoc """
  A struct that represents the `intent` portion of the clova request. For the representation
  of the entire request, see `Clova.Request`.

  The intent `:name` is passed to the `c:Clova.handle_intent/3` callback.

  Data can be retrieved from named slots using `Clova.Request.get_slot/2`.
  """
  defstruct [:name, :slots]
end

defmodule Clova.Request.Request do
  @moduledoc """
  A struct that represents the `request` portion of the clova request. For the representation
  of the entire request, see `Clova.Request`.
  """
  defstruct type: nil, intent: %Clova.Request.Intent{}
end

defmodule Clova.Request.User do
  @moduledoc """
  A struct that represents the `user` portion of the clova request. For the representation
  of the entire request, see `Clova.Request`.
  """
  defstruct [:userId, :accessToken]
end

defmodule Clova.Request.Session do
  @moduledoc """
  A struct that represents the `session` portion of the clova request. For the representation
  of the entire request, see `Clova.Request`.
  """
  defstruct sessionId: nil, new: false, user: %Clova.Request.User{}, sessionAttributes: %{}
end

defmodule Clova.Request.System do
  @moduledoc """
  A struct that represents the  `"System"` portion of the clova request. For the representation
  of the entire request, see `Clova.Request`.
  """
  defstruct application: %{"applicationId" => nil},
            device: %{"deviceId" => nil},
            user: %Clova.Request.User{}
end

defmodule Clova.Request.Context do
  @moduledoc """
  A struct that represents the `context` portion of the clova request. For the representation
  of the entire request, see `Clova.Request`.
  """
  defstruct System: %Clova.Request.System{}
end

defmodule Clova.Request do
  @moduledoc """
  Represents the result of decoding the JSON data recevied from Clova.
  """

  defstruct version: "1.0",
            session: %Clova.Request.Session{},
            context: %Clova.Request.Context{},
            request: %Clova.Request.Request{}

  @doc """
  Helper function to retrieve the data of a named slot from a clova request. Returns
  the retrieved data, or `nil` if not present.
  """
  def get_slot(request, slot_name) do
    slots = request.request.intent.slots

    if slots == nil do
      nil
    else
      case Map.get(slots, slot_name) do
        nil -> nil
        slot -> slot["value"]
      end
    end
  end

  @doc """
  Helper function to retrieve the session attributes.
  """
  def get_session_attributes(request) do
    request.session.sessionAttributes()
  end
end
