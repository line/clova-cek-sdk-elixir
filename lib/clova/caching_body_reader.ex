defmodule Clova.CachingBodyReader do
  @moduledoc """
  This module provides a wrapper of `Plug.Conn.read_body/2` that also stores the original raw request
  body in the `:raw_body` assign. This is required to validate the request signature.
  The `Clova.ValidatorPlug` module provides request validation using this module.
  """

  @doc """
  Wraps `Plug.Conn.read_body/2`, caching the result in the `:raw_body` assign.
  """
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {res, body, conn} when res in [:ok, :more] ->
        {res, body, update_in(conn.assigns[:raw_body], &((&1 || "") <> body))}

      unknown ->
        unknown
    end
  end

  @doc """
  The specification of this module's `read_body/2` function for providing to `Plug.Parsers`'
  `body_reader` option.
  """
  def spec, do: {__MODULE__, :read_body, []}
end
