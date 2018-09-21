defmodule Clova.Response.SpeechInfoObject do
  @moduledoc """
  A struct that represents a `SpeechInfoObject` entry of the clova response. For the representation
  of the entire response see `Clova.Response`.
  """
  defstruct lang: "ja", type: "PlainText", value: nil
end

defmodule Clova.Response.OutputSpeech do
  @moduledoc """
  A struct that represents an `outputSpeech` entry of the clova response. For the representation
  of the entire response see `Clova.Response`.
  """
  defstruct type: "SimpleSpeech", values: %Clova.Response.SpeechInfoObject{}
end

defmodule Clova.Response.Reprompt do
  @moduledoc """
  A struct that represents a `reprompt` entry of the clova response. For the representation
  of the entire response see `Clova.Response`.
  """
  defstruct outputSpeech: %Clova.Response.OutputSpeech{}
end

defmodule Clova.Response.Response do
  @moduledoc """
  A struct that represents the `response` portion of the clova response. For the representation
  of the entire response see `Clova.Response`.
  """
  defstruct outputSpeech: %Clova.Response.OutputSpeech{},
            shouldEndSession: false,
            card: nil,
            directives: nil,
            reprompt: nil
end

defmodule Clova.Response do
  @moduledoc """
  Defines a struct that contains the data that should be encoded into JSON as a response to a clova request.

  An intance of this struct is initialised by the `Clova.DispatcherPlug` and passed to the
  callbacks defined by the `Clova` behaviour.
  """

  defstruct response: %Clova.Response.Response{}, sessionAttributes: %{}, version: "1.0"

  @doc """
  Appends the specified `speech` to the response. `speech` can be Japanese text or a URL. When
  passing a URL, set the `type` argument to `:url`.

  This function automatically upgrades a `SimpleSpeech`
  response to a `SpeechList` response if the response already contained a non-nil `SimpleSpeech`
  string. If the response was empty, and only one utterance is provided, a `SimpleSpeech` response is created.
  """
  def add_speech(resp, speech, type \\ :text) do
    output_speech = add_speech_to_output_speech(resp.response.outputSpeech, speech, type)
    put_in(resp.response.outputSpeech, output_speech)
  end

  @doc """
  Adds the specified `speech` to the response's `reprompt` data. This is used by Clova to
  reprompt the user for an utterance when clova is expecting a reply but none is detected.

  `speech` can be Japanese text or a URL. When passing a URL, set the `type` argument to `:url`.
  """
  def add_reprompt(resp, speech, type \\ :text) do
    reprompt = resp.response.reprompt || %Clova.Response.Reprompt{}
    output_speech = add_speech_to_output_speech(reprompt.outputSpeech, speech, type)
    reprompt = put_in(reprompt.outputSpeech, output_speech)
    put_in(resp.response.reprompt, reprompt)
  end

  @doc """
  Places the supplied `session_attributes` object into the response. The same data will be
  included in any subsequent clova request during the session. Subsequent calls to this function
  will overwrite the data from previous calls.

  `session_attributes` should be formatted as a key, value map.
  """
  def put_session_attributes(resp, session_attributes) do
    put_in(resp.sessionAttributes, session_attributes)
  end

  @doc """
  Sets the `shouldEndSession` flag of `response` to `true`.
  """
  def end_session(response) do
    put_in(response.response.shouldEndSession, true)
  end

  defp add_speech_to_output_speech(output_speech, speech, :text) do
    speech_info = %Clova.Response.SpeechInfoObject{value: speech}
    add_speech_info_to_output_speech(output_speech, speech_info)
  end

  defp add_speech_to_output_speech(output_speech, speech, :url) do
    speech_info = %Clova.Response.SpeechInfoObject{type: "URL", value: speech, lang: ""}
    add_speech_info_to_output_speech(output_speech, speech_info)
  end

  defp add_speech_info_to_output_speech(output_speech = %{type: "SpeechList"}, speech_info) do
    update_in(output_speech.values, &(&1 ++ [speech_info]))
  end

  defp add_speech_info_to_output_speech(output_speech = %{type: "SimpleSpeech"}, speech_info) do
    if output_speech.values.value == nil do
      put_in(output_speech.values, speech_info)
    else
      %{output_speech | type: "SpeechList", values: [output_speech.values, speech_info]}
    end
  end
end
