defmodule Clova.ValidatorPlugTest do
  use ExUnit.Case
  use Plug.Test
  alias Clova.ValidatorPlug

  # To Generate keys:
  # openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -pkeyopt rsa_keygen_pubexp:65537 -out private.pem
  # openssl pkey -pubout -inform PEM -outform PEM -in private.pem -out test_public.pem

  @public_key_file "test/keys/public.pem"
  @private_key_file "test/keys/private.pem"

  setup_all context do
    public_key = load_pub_key(@public_key_file)
    private_key = load_priv_key(@private_key_file)

    context
    |> Map.put(:public_key, public_key)
    |> Map.put(:private_key, private_key)
  end

  test "init uses the default public key" do
    %{public_key: default_key, app_id: nil} = ValidatorPlug.init([])
    {:RSAPublicKey, data, _} = default_key
    assert to_string(data) |> String.starts_with?("2450758132787322")
  end

  test "Fails when the signature is missing" do
    conn = make_conn()
    opts = %{public_key: "dummy", app_id: "dummy", force_signature_valid: false}

    conn = Clova.ValidatorPlug.call(conn, opts)
    assert conn.resp_body === "Message unsigned"
    assert conn.status === 403
    refute conn.assigns.clova_valid
  end

  test "Fails if the signature is not base-64 encoded" do
    conn =
      make_conn()
      |> put_req_header("signaturecek", "forgot to base64 encode")

    opts = %{public_key: "dummy", app_id: "dummy", force_signature_valid: false}

    conn = Clova.ValidatorPlug.call(conn, opts)
    assert conn.resp_body === "Signature not Base64 encoded"
    assert conn.status === 403
    refute conn.assigns.clova_valid
  end

  test "Fails with a dump of the header if could not parse for unknown reason" do
    conn =
      make_conn()
      # Put in two signaturecek headers to confuse things
      |> put_req_header("signaturecek", "one")
      |> Map.update!(:req_headers, &(&1 ++ [{"signaturecek", "two"}]))

    opts = %{public_key: "dummy", app_id: "dummy", force_signature_valid: false}

    conn = Clova.ValidatorPlug.call(conn, opts)
    assert conn.resp_body === ~S(Signature header in unexpected format: ["one", "two"])
    assert conn.status === 403
    refute conn.assigns.clova_valid
  end

  test "when the signature does not validate, returns unauthorized response", %{
    public_key: public_key
  } do
    conn =
      conn(:post, "/clova", "")
      |> put_req_header("signaturecek", "aGVsbG8=")
      |> assign(:raw_body, "different_data")

    conn =
      Clova.ValidatorPlug.call(conn, %{
        public_key: public_key,
        app_id: nil,
        force_signature_valid: false
      })

    assert conn.status === 403
    refute conn.assigns.clova_valid
    assert conn.resp_body === "Signature invalid"
  end

  test "when the signature does validate, sets :clova_valid to true",
       %{public_key: public_key, private_key: private_key} do
    sig =
      :public_key.sign("signed data", :sha256, private_key)
      |> Base.encode64()

    conn =
      conn(:post, "/clova", "")
      |> put_req_header("signaturecek", sig)
      |> assign(:raw_body, "signed data")

    conn =
      Clova.ValidatorPlug.call(conn, %{
        public_key: public_key,
        app_id: nil,
        force_signature_valid: false
      })

    assert conn.assigns.clova_valid
  end

  test "when force_signature_valid is used, signature is validated even if it's invalid",
       %{public_key: public_key, private_key: private_key} do
    sig =
      :public_key.sign("signed data", :sha256, private_key)
      |> Base.encode64()

    conn =
      conn(:post, "/clova", "")
      |> put_req_header("signaturecek", sig)
      |> assign(:raw_body, "invalid data")
      |> Map.put(:body_params, make_body_params("test.matching.id"))

    conn =
      Clova.ValidatorPlug.call(conn, %{
        public_key: public_key,
        app_id: "test.matching.id",
        force_signature_valid: true
      })

    assert conn.assigns.clova_valid

    conn =
      Clova.ValidatorPlug.call(conn, %{
        public_key: public_key,
        app_id: "test.matching.id",
        force_signature_valid: false
      })

    refute conn.assigns.clova_valid
  end

  test "when app_id is set, and it's different to actual app_id, validation fails" do
    conn =
      conn(:post, "/clova", "")
      |> put_req_header("signaturecek", "aGVsbG8=")
      |> assign(:raw_body, "dummy")
      |> Map.put(:body_params, make_body_params("test.actual.id"))

    conn =
      Clova.ValidatorPlug.call(conn, %{
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
    sig =
      :public_key.sign("signed data", :sha256, private_key)
      |> Base.encode64()

    conn =
      conn(:post, "/clova", "")
      |> put_req_header("signaturecek", sig)
      |> assign(:raw_body, "signed data")
      |> Map.put(:body_params, make_body_params("test.matching.id"))

    conn =
      Clova.ValidatorPlug.call(conn, %{
        public_key: public_key,
        app_id: "test.matching.id",
        force_signature_valid: false
      })

    assert conn.assigns.clova_valid
  end

  defp load_pub_key(filename) do
    File.read!(filename)
    |> :public_key.pem_decode()
    |> hd
    |> :public_key.pem_entry_decode()
  end

  defp load_priv_key(filename) do
    private_key_der =
      File.read!(filename)
      |> :public_key.pem_decode()
      |> hd
      |> :public_key.pem_entry_decode()
      |> elem(3)

    :public_key.der_decode(:RSAPrivateKey, private_key_der)
  end

  defp make_body_params(app_id \\ "com.example.app") do
    %{"context" => %{"System" => %{"application" => %{"applicationId" => app_id}}}}
  end

  defp make_conn do
    dummy_body = "{}"

    conn(:post, "/clova", dummy_body)
    |> put_req_header("content-type", "application/json")
    |> assign(:raw_body, dummy_body)
    |> Map.put(:body_params, make_body_params())
  end
end
