defmodule Dwolla.TokenTest do
  use ExUnit.Case

  import Dwolla.Factory

  setup do
    bypass = Bypass.open()
    Application.put_env(:dwolla, :root_uri, "http://localhost:#{bypass.port}/")
    {:ok, bypass: bypass}
  end

  describe "token" do
    test "get/1 requests POST and returns Dwolla.Token", %{bypass: bypass} do
      body = http_response_body(:token)

      Bypass.expect(bypass, fn conn ->
        assert "POST" == conn.method
        Plug.Conn.resp(conn, 200, Poison.encode!(body))
      end)

      assert {:ok, resp} = Dwolla.Token.get()
      assert resp.__struct__ == Dwolla.Token
      refute resp.access_token == nil
      refute resp.expires_in == nil
      refute resp.token_type == nil
    end

    test "get/1 requests POST and returns HTTPoison.Error", %{bypass: bypass} do
      Bypass.down(bypass)

      assert {:error, %HTTPoison.Error{}} = Dwolla.Token.get()
    end
  end
end
