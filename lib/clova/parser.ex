defmodule Clova.Parser do
  import Plug.Conn
  @behaviour Plug.Parsers

  @moduledoc """
  Parses the request body and signature header.

  Usage:

  ```
  plug Plug.Parsers, parsers: [Clova.Parser]
  ```

  The request body is parsed into a `Clova.Request` struct, which is later provided
  as the `request` argument to the `Clova` callbacks. Raises `Plug.Parsers.ParseError` if
  the request body could not be decoded.

  The request signature is parsed from the `signaturecek` header and placed into the `:signature`
  assign as an `{:ok, signature}` tuple if successful, or if the signature could not be parsed,
  an `{:error, reason}` tuple.

  This module also stores the original raw request body in the `:raw_body` assign,
  because it is required to validate the request signature. For request validation it
  is recommended to use the `Clova.Validator` plug.

  """

  def init(opts) do
    opts
  end

  def parse(conn, "application", "json", _params, _state) do
    {:ok, raw_body, conn} = read_body(conn)
    conn = assign(conn, :raw_body, raw_body)
    conn = assign(conn, :signature, get_signature(conn))

    # Would prefer to use non-raising Poison.decode/2 here, but then its necessary
    # to re-implement the error handling, so just let it raise an exception and rethrow it
    try do
      clova_req = Poison.decode!(raw_body, as: %Clova.Request{})
      {:ok, clova_req, conn}
    rescue
      e -> raise Plug.Parsers.ParseError, exception: e
    end
  end

  def parse(conn, _type, _subtype, _params, _state) do
    {:next, conn}
  end

  defp get_signature(conn) do
    with [signature_header] <- get_req_header(conn, "signaturecek"),
         {:ok, signature} <- Base.decode64(signature_header) do
      {:ok, signature}
    else
      [] -> {:error, "Message unsigned"}
      :error -> {:error, "Signature not Base64 encoded"}
      err -> {:error, err}
    end
  end
end
