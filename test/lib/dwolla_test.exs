defmodule DwollaTest do
  use ExUnit.Case

  alias Plug.Conn

  setup do
    bypass = Bypass.open()
    Application.put_env(:dwolla, :root_uri, "http://localhost:#{bypass.port}/")
    {:ok, bypass: bypass}
  end

  describe "dwolla" do
    test "get_cred/0 returns credentials as a map" do
      assert %{client_id: _, client_secret: _} = Dwolla.get_cred()
    end

    test "get_cred/0 raises when client_id is missing" do
      Application.put_env(:dwolla, :client_id, nil)
      assert_raise Dwolla.MissingClientIdError, fn -> Dwolla.get_cred() end
      cleanup_config()
    end

    test "get_cred/0 raises when secret is missing" do
      Application.put_env(:dwolla, :client_secret, nil)
      assert_raise Dwolla.MissingClientSecretError, fn -> Dwolla.get_cred() end
      cleanup_config()
    end

    test "make_request_with_token/3 raises when root_uri is missing" do
      Application.put_env(:dwolla, :root_uri, nil)

      assert_raise Dwolla.MissingRootUriError, fn ->
        Dwolla.make_request_with_token(:get, "any", "token")
      end
    end

    test "make_request_with_token/3 requests GET returns HTTPoison.Response", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        assert "GET" == conn.method
        Conn.resp(conn, 200, "{\"status\":\"ok\"}")
      end)

      assert {:ok, %HTTPoison.Response{}} = Dwolla.make_request_with_token(:get, "any", "token")
    end

    test "make_request_with_token/3 returns error tuple when HTTP call fails", %{bypass: bypass} do
      Bypass.down(bypass)

      assert {:error, %HTTPoison.Error{}} = Dwolla.make_request_with_token(:get, "any", "token")
    end

    test "make_oauth_token_request/2 merges credentials into request body", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        {:ok, body, _conn} = Conn.read_body(conn)
        assert "POST" == conn.method
        assert "client_id=id&client_secret=shhhh" == body
        Conn.resp(conn, 200, "{\"status\":\"ok\"}")
      end)

      Dwolla.make_oauth_token_request(%{}, %{client_id: "id", client_secret: "shhhh"})
    end

    test "make_oauth_token_request/2 returns error tuple when HTTP call fails", %{bypass: bypass} do
      Bypass.down(bypass)

      assert {:error, %HTTPoison.Error{}} =
               Dwolla.make_oauth_token_request(%{}, %{client_id: "id", client_secret: "shhhh"})
    end

    test "make_request_with_token/3 sets headers correctly", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        content_type =
          Enum.find(conn.req_headers, fn {k, _v} ->
            k == "content-type"
          end)

        assert {"content-type", "application/vnd.dwolla.v1.hal+json"} == content_type
        Conn.resp(conn, 200, "{\"status\":\"ok\"}")
      end)

      Dwolla.make_request_with_token(:get, "any", "token")
    end

    test "make_oauth_token_request/2 sets headers correctly", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        content_type =
          Enum.find(conn.req_headers, fn {k, _v} ->
            k == "content-type"
          end)

        assert {"content-type", "application/x-www-form-urlencoded"} == content_type
        Conn.resp(conn, 200, "{\"status\":\"ok\"}")
      end)

      Dwolla.make_oauth_token_request(%{}, %{client_id: "id", client_secret: "shhhh"})
    end

    test "make_request_with_token/3 makes payload camel case", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        {:ok, body, _conn} = Conn.read_body(conn)
        assert "POST" == conn.method
        assert "{\"firstName\":\"Steve\"}" == body
        Conn.resp(conn, 200, "")
      end)

      Dwolla.make_request_with_token(:post, "any", "token", %{first_name: "Steve"})
    end
  end

  defp cleanup_config do
    Application.put_env(:dwolla, :client_id, "my_client_id")
    Application.put_env(:dwolla, :client_secret, "my_client_secret")
  end
end
