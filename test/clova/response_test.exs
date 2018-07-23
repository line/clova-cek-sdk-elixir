defmodule Clova.ResponseTest do
  use ExUnit.Case
  doctest Clova.Response

  test "empty struct has correct defaults" do
    msg = %Clova.Response{}
    assert msg.sessionAttributes == %{}
    assert msg.version == "1.0"

    response = msg.response
    assert %Clova.Response.Response{} = response
    refute response.shouldEndSession
    assert response.card == nil
    assert response.directives == nil

    output_speech = response.outputSpeech
    assert %Clova.Response.OutputSpeech{} = output_speech
    assert output_speech.type == "SimpleSpeech"

    simple_speech = output_speech.values
    assert %Clova.Response.SpeechInfoObject{} = simple_speech
    assert simple_speech.lang == "ja"
    assert simple_speech.type == "PlainText"
    assert simple_speech.value == nil
  end

  test "add_speech(string) updates nil SimpleSpeech response" do
    empty_msg = %Clova.Response{}
    foo_msg = Clova.Response.add_speech(empty_msg, "foo")
    assert foo_msg.response.outputSpeech.type == "SimpleSpeech"
    assert foo_msg.response.outputSpeech.values.value == "foo"
  end

  test "add_speech(string) converts SimpleSpeech to SpeechList and adds string" do
    foo_msg = Clova.Response.add_speech(%Clova.Response{}, "foo")
    assert foo_msg.response.outputSpeech.type == "SimpleSpeech"
    assert foo_msg.response.outputSpeech.values.value == "foo"
    bar_msg = Clova.Response.add_speech(foo_msg, "bar")
    assert bar_msg.response.outputSpeech.type == "SpeechList"
    [foo_speech, bar_speech] = bar_msg.response.outputSpeech.values
    assert foo_speech.value == "foo"
    assert bar_speech.value == "bar"
  end

  test "add_speech(list) adds string to SpeechList" do
    foo_simple_speech = %Clova.Response.SpeechInfoObject{value: "foo"}

    foo_output_speech_list = %Clova.Response.OutputSpeech{
      type: "SpeechList",
      values: [foo_simple_speech]
    }

    foo_msg = %Clova.Response{
      response: %Clova.Response.Response{outputSpeech: foo_output_speech_list}
    }

    bar_msg = Clova.Response.add_speech(foo_msg, "bar")
    assert bar_msg.response.outputSpeech.type == "SpeechList"
    [foo_speech, bar_speech] = bar_msg.response.outputSpeech.values
    assert foo_speech.value == "foo"
    assert bar_speech.value == "bar"
  end

  test "add_speech with url? flag is reflected in the SpeechInfoObjecjt's type" do
    empty_msg = %Clova.Response{}
    url_msg = Clova.Response.add_speech(empty_msg, "url", true)
    assert url_msg.response.outputSpeech.values.value == "url"
    assert url_msg.response.outputSpeech.values.type == "URL"

    not_url_msg = Clova.Response.add_speech(empty_msg, "not url", false)
    assert not_url_msg.response.outputSpeech.values.value == "not url"
    assert not_url_msg.response.outputSpeech.values.type == "PlainText"

    default_msg = Clova.Response.add_speech(empty_msg, "default")
    assert default_msg.response.outputSpeech.values.value == "default"
    assert default_msg.response.outputSpeech.values.type == "PlainText"
  end

  test "end_session sets shouldEndSession to true" do
    default = %Clova.Response{}
    refute default.response.shouldEndSession
    ended = Clova.Response.end_session(default)
    assert ended.response.shouldEndSession
  end

  test "add_reprompt adds a the repromt data" do
    default = %Clova.Response{}
    assert default.response.reprompt == nil
    reprompted = Clova.Response.add_reprompt(default, "foo")
    assert reprompted.response.reprompt.outputSpeech.values.value == "foo"
    extra = Clova.Response.add_reprompt(reprompted, "bar")
    [foo_speech, bar_speech] = extra.response.reprompt.outputSpeech.values
    assert foo_speech.value == "foo"
    assert bar_speech.value == "bar"
  end

  test "add_reprompt url? flag is reflected in the SpeechInfoObject type" do
    resp =
      %Clova.Response{}
      |> Clova.Response.add_reprompt("foo", true)
      |> Clova.Response.add_reprompt("bar", false)
      |> Clova.Response.add_reprompt("baz")

    [foo_speech, bar_speech, baz_speech] = resp.response.reprompt.outputSpeech.values
    assert foo_speech.value == "foo"
    assert bar_speech.value == "bar"
    assert baz_speech.value == "baz"
    assert foo_speech.type == "URL"
    assert bar_speech.type == "PlainText"
    assert baz_speech.type == "PlainText"
  end
end
