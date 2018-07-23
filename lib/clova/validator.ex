defmodule Clova.Validator do
  import Plug.Conn
  @behaviour Plug

  @pubkey """
  -----BEGIN PUBLIC KEY-----
  MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwiMvQNKD/WQcX9KiWNMb
  nSR+dJYTWL6TmqqwWFia69TyiobVIfGfxFSefxYyMTcFznoGCpg8aOCAkMxUH58N
  0/UtWWvfq0U5FQN9McE3zP+rVL3Qul9fbC2mxvazxpv5KT7HEp780Yew777cVPUv
  3+I73z2t0EHnkwMesmpUA/2Rp8fW8vZE4jfiTRm5vSVmW9F37GC5TEhPwaiIkIin
  KCrH0rXbfe3jNWR7qKOvVDytcWgRHJqRUuWhwJuAnuuqLvqTyAawqEslhKZ5t+1Z
  0GN8b2zMENSuixa1M9K0ZKUw3unzHpvgBlYmXRGPTSuq/EaGYWyckYz8CBq5Lz2Q
  UwIDAQAB
  -----END PUBLIC KEY-----
  """

  @moduledoc """
  Validates the HTTP request body against the `signaturecek` header and provided `app_id`.

  CEK requests are signed by the server. This module verifies the signature using the published
  public key. If the signature is invalid, the connection state is set to 403 Forbidden
  and the plug pipeline is halted.

  Usage:
  ```
  plug Clova.Validator, app_id: "com.example.my_extension"
  ```

  ## Options

  * `:app_id` - The application ID as specified in the Clova Developer Center. All requests must contain this ID in the request body. If this option is not provided, the app ID validity is not checked.
  * `:force_signature_valid` - forces the plug to consider the signature to be valid. This is intended for use in development, because only requests signed by the CEK server will validate against the default public key.
  * `:public_key` - override the public key used by this plug. This can be used during testing and development to validate requests generated with the corresponding private key. Alternatievely if the CEK server changes its public key, this can be used to override the default key used by this module until an updated version of this module is available.

  """

  def init(opts) do
    opts
    |> Keyword.put_new(:app_id, nil)
    |> Keyword.put_new(:force_signature_valid, false)
    |> Keyword.put_new_lazy(:public_key, fn -> ExPublicKey.loads!(@pubkey) end)
    |> Enum.into(%{})
  end

  def call(
        conn = %{assigns: %{signature: {:ok, signature}, raw_body: body}},
        %{public_key: public_key, app_id: expected_id, force_signature_valid: force}
      ) do
    app_id =
      if expected_id do
        conn.body_params.context."System".application["applicationId"]
      else
        nil
      end

    cond do
      !signature_valid?(body, signature, public_key, force) ->
        unauthorized(conn, "Signature invalid")

      !app_id_valid?(expected_id, app_id) ->
        unauthorized(conn, "Expected applicationId #{expected_id}, got #{app_id}")

      true ->
        assign(conn, :clova_valid, true)
    end
  end

  def call(conn = %{assigns: %{signature: {:error, reason}}}, _opts) do
    unauthorized(conn, reason)
  end

  def call(conn, _opts) do
    unauthorized(conn, "Invalid request (validation falied)")
  end

  defp unauthorized(conn, why) do
    conn
    |> assign(:clova_valid, false)
    |> halt
    |> send_resp(:forbidden, why)
  end

  defp app_id_valid?(expected, actual), do: !expected || expected === actual

  defp signature_valid?(body, signature, public_key, force) do
    if force do
      true
    else
      {:ok, valid} = ExPublicKey.verify(body, signature, public_key)
      valid
    end
  end
end
