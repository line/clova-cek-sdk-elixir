defmodule Clova.ValidatorTest do
  use ExUnit.Case
  use Plug.Test
  alias Clova.Validator

  # To Generate keys:
  # openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -pkeyopt rsa_keygen_pubexp:65537 -out private.pem
  # openssl pkey -pubout -inform PEM -outform PEM -in private.pem -out test_public.pem

  @public_key_file "test/keys/public.pem"
  @private_key_file "test/keys/private.pem"

  setup_all context do
    public_key = ExPublicKey.load!(@public_key_file)
    private_key = load_priv_key(@private_key_file)

    public_fingerprint = ExPublicKey.RSAPublicKey.get_fingerprint(public_key)
    private_fingerprint = ExPublicKey.RSAPrivateKey.get_fingerprint(private_key)
    assert public_fingerprint === private_fingerprint

    context
    |> Map.put(:public_key, public_key)
    |> Map.put(:private_key, private_key)
  end

  test "init uses the default public key" do
    expected_fingerprint = "0aa9590f35a0646b12ceeb09103ba0cbdde4a97b8dca10d956550f3f8c1bee86"
    %{public_key: default_key, app_id: nil} = Validator.init([])
    actual_fingerprint = ExPublicKey.RSAPublicKey.get_fingerprint(default_key)
    assert expected_fingerprint === actual_fingerprint
  end

  test "when the signature could not be parsed, returns unauthorized response", %{
    public_key: public_key
  } do
    conn =
      conn(:post, "/clova", "")
      |> assign(:signature, {:error, "oops"})
      |> assign(:raw_body, ~S(["dummy json"]))

    conn =
      Clova.Validator.call(conn, %{
        public_key: public_key,
        app_id: nil,
        force_signature_valid: false
      })

    assert conn.status === 403
    refute conn.assigns.clova_valid
  end

  test "when the signature does not validate, returns unauthorized response",
       %{public_key: public_key, private_key: private_key} do
    sig = ExPublicKey.sign("signed data", private_key)

    conn =
      conn(:post, "/clova", "")
      |> assign(:signature, {:ok, sig})
      |> assign(:raw_body, "different_data")

    conn =
      Clova.Validator.call(conn, %{
        public_key: public_key,
        app_id: nil,
        force_signature_valid: false
      })

    assert conn.status === 403
    refute conn.assigns.clova_valid
  end

  test "when the signature does validate, sets :clova_valid to true",
       %{public_key: public_key, private_key: private_key} do
    sig = ExPublicKey.sign("signed data", private_key)

    conn =
      conn(:post, "/clova", "")
      |> assign(:signature, sig)
      |> assign(:raw_body, "signed data")

    conn =
      Clova.Validator.call(conn, %{
        public_key: public_key,
        app_id: nil,
        force_signature_valid: false
      })

    assert conn.assigns.clova_valid
  end

  test "when force_signature_valid is used, signature is validated even if it's invalid",
       %{public_key: public_key, private_key: private_key} do
    sig = ExPublicKey.sign("signed data", private_key)

    conn =
      conn(:post, "/clova", "")
      |> assign(:signature, sig)
      |> assign(:raw_body, "invalid data")
      |> Map.put(:body_params, make_req_with_app_id("test.matching.id"))

    conn =
      Clova.Validator.call(conn, %{
        public_key: public_key,
        app_id: "test.matching.id",
        force_signature_valid: true
      })

    assert conn.assigns.clova_valid

    conn =
      Clova.Validator.call(conn, %{
        public_key: public_key,
        app_id: "test.matching.id",
        force_signature_valid: false
      })

    refute conn.assigns.clova_valid
  end

  test "when app_id is set, and it's different to actual app_id, validation fails" do
    conn =
      conn(:post, "/clova", "")
      |> assign(:signature, {:ok, "dummy sig"})
      |> assign(:raw_body, "dummy")
      |> Map.put(:body_params, make_req_with_app_id("test.actual.id"))

    conn =
      Clova.Validator.call(conn, %{
        public_key: "dummy public key",
        app_id: "test.expected.id",
        force_signature_valid: true
      })

    assert conn.status === 403
    refute conn.assigns.clova_valid
    assert conn.resp_body == "Expected applicationId test.expected.id, got test.actual.id"
  end

  test "when app_id is set and the request matches, validation passes",
       %{public_key: public_key, private_key: private_key} do
    sig = ExPublicKey.sign("signed data", private_key)

    conn =
      conn(:post, "/clova", "")
      |> assign(:signature, sig)
      |> assign(:raw_body, "signed data")
      |> Map.put(:body_params, make_req_with_app_id("test.matching.id"))

    conn =
      Clova.Validator.call(conn, %{
        public_key: public_key,
        app_id: "test.matching.id",
        force_signature_valid: false
      })

    assert conn.assigns.clova_valid
  end

  # This is a workaround because ExPublicKey.load() does not work with PEM private keys
  # See https://github.com/ntrepid8/ex_crypto/issues/27
  defp load_priv_key(filename) do
    {:PrivateKeyInfo, :v1, _, private_key_binary, _} =
      File.read!(filename)
      |> :public_key.pem_decode()
      |> hd
      |> :public_key.pem_entry_decode()

    :public_key.der_decode(:RSAPrivateKey, private_key_binary)
    |> ExPublicKey.RSAPrivateKey.from_sequence()
  end

  defp make_req_with_app_id(app_id) do
    %Clova.Request{
      context: %Clova.Request.Context{
        System: %Clova.Request.System{
          application: %{
            "applicationId" => app_id
          }
        }
      }
    }
  end
end
