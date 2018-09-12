defmodule Clova.MixProject do
  use Mix.Project

  @version "0.2.2"

  def project do
    [
      app: :clova,
      version: @version,
      elixir: "~> 1.6",
      deps: deps(),
      description: "LINE Clova Extension SDK",
      package: package(),
      name: "Clova",
      source_url: "https://github.com/line/clova-cek-sdk-elixir",
      homepage_url: "https://clova-developers.line.me/",
      docs: docs()
    ]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      links: %{
        "Project Homepage" => "https://clova-developers.line.me/",
        "GitHub" => "https://github.com/line/clova-cek-sdk-elixir",
        "Sample Usage" => "https://github.com/line/clova-cek-sdk-elixir-sample"
      },
      files: ~w[
        lib
        test
        mix.exs
        .formatter.exs
        README.md
        LICENSE.txt
        LEGAL_NOTICE.md
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      groups_for_modules: [
        Plug: [
          Clova.Parser,
          Clova.Validator,
          Clova.Dispatcher
        ],
        Request: [
          Clova.Request,
          Clova.Request.Session,
          Clova.Request.Context,
          Clova.Request.Request,
          Clova.Request.System,
          Clova.Request.User,
          Clova.Request.Intent
        ],
        Response: [
          Clova.Response,
          Clova.Response.Response,
          Clova.Response.Reprompt,
          Clova.Response.OutputSpeech,
          Clova.Response.SimpleSpeech,
          Clova.Response.SpeechInfoObject
        ]
      ]
    ]
  end

  def deps do
    [
      {:plug, "~> 1.5"},
      {:poison, "~> 3.1"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end
end
