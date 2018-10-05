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

  test "add_speech handles :type and :lang optional args" do
    resp =
      %Clova.Response{}
      |> Clova.Response.add_speech("test1")
      |> Clova.Response.add_speech("test2", type: :text)
      |> Clova.Response.add_speech("test3", lang: "en")
      |> Clova.Response.add_speech("test4", type: :text, lang: "en")
      |> Clova.Response.add_speech("test5", lang: "en", type: :text)
      |> Clova.Response.add_speech("test6", type: :url, lang: "en")
      |> Clova.Response.add_speech("test7", lang: "ja", type: :url)

    [default, text, lang, text_lang, lang_text, url1, url2] = resp.response.outputSpeech.values

    assert %{type: "PlainText", lang: "ja"} = default
    assert %{type: "PlainText", lang: "ja"} = text
    assert %{type: "PlainText", lang: "en"} = lang
    assert %{type: "PlainText", lang: "en"} = text_lang
    assert %{type: "PlainText", lang: "en"} = lang_text
    assert %{type: "URL", lang: ""} = url1
    assert %{type: "URL", lang: ""} = url2
  end

  test "end_session sets shouldEndSession to true" do
    default = %Clova.Response{}
    refute default.response.shouldEndSession
    ended = Clova.Response.end_session(default)
    assert ended.response.shouldEndSession
  end

  test "add_reprompt adds the reprompt data" do
    default = %Clova.Response{}
    assert default.response.reprompt == nil
    reprompted = Clova.Response.add_reprompt(default, "foo")
    assert reprompted.response.reprompt.outputSpeech.values.value == "foo"
    extra = Clova.Response.add_reprompt(reprompted, "bar")
    [foo_speech, bar_speech] = extra.response.reprompt.outputSpeech.values
    assert foo_speech.value == "foo"
    assert bar_speech.value == "bar"
  end

  test "add_reprompt handles :type and :lang optional args" do
    resp =
      %Clova.Response{}
      |> Clova.Response.add_reprompt("default")
      |> Clova.Response.add_reprompt("text", type: :text)
      |> Clova.Response.add_reprompt("text_and_lang", type: :text, lang: "en")
      |> Clova.Response.add_reprompt("lang_and_text", lang: "en", type: :text)
      |> Clova.Response.add_reprompt("url", type: :url)
      |> Clova.Response.add_reprompt("url_and_lang", type: :url, lang: "ja")

    [default, text, text_and_lang, lang_and_text, url, url_and_lang] =
      resp.response.reprompt.outputSpeech.values

    assert %{lang: "ja", type: "PlainText"} = default
    assert %{lang: "ja", type: "PlainText"} = text
    assert %{lang: "en", type: "PlainText"} = text_and_lang
    assert %{lang: "en", type: "PlainText"} = lang_and_text
    assert %{lang: "", type: "URL"} = url
    assert %{lang: "", type: "URL"} = url_and_lang
  end
end
