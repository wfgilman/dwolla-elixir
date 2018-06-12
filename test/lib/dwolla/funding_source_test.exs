defmodule Dwolla.FundingSourceTest do

  use ExUnit.Case

  import Dwolla.Factory

  alias Dwolla.FundingSource
  alias Plug.Conn

  setup do
    bypass = Bypass.open()
    Application.put_env(:dwolla, :root_uri, "http://localhost:#{bypass.port}/")
    {:ok, bypass: bypass}
  end

  describe "funding-source" do

    test "get/2 requests GET and returns Dwolla.FundingSource", %{bypass: bypass} do
      body = http_response_body(:funding_source, :get)
      Bypass.expect bypass, fn conn ->
        assert "GET" == conn.method
        Conn.resp(conn, 200, body)
      end

      assert {:ok, resp} = FundingSource.get("token", "id")
      assert resp.__struct__ == Dwolla.FundingSource
      refute resp.id == nil
      refute resp.created == nil
      refute resp.name == nil
      refute resp.removed == nil
      refute resp.status == nil
      refute resp.type == nil
      refute resp.channels == nil
      refute resp.bankName == nil
    end

    test "update/3 requests POST and returns Dwolla.FundingSource", %{bypass: bypass} do
      body = http_response_body(:funding_source, :get)
      Bypass.expect bypass, fn conn ->
        assert "POST" == conn.method
        Conn.resp(conn, 200, body)
      end

      assert {:ok, resp} = FundingSource.update_name("token", "id", "My Checking")
      assert resp.__struct__ == Dwolla.FundingSource
    end

    test "remove/2 requests POST and returns Dwolla.FundingSource", %{bypass: bypass} do
      body = http_response_body(:funding_source, :get)
      Bypass.expect bypass, fn conn ->
        assert "POST" == conn.method
        Conn.resp(conn, 200, body)
      end

      assert {:ok, resp} = FundingSource.remove("token", "id")
      assert resp.__struct__ == Dwolla.FundingSource
    end

    test "balance/2 requests GET and returns Dwolla.FundingSource.Balance", %{bypass: bypass} do
      body = http_response_body(:balance, :get)
      Bypass.expect bypass, fn conn ->
        assert "GET" == conn.method
        Conn.resp(conn, 200, body)
      end

      assert {:ok, resp} = FundingSource.balance("token", "id")
      assert resp.__struct__ == Dwolla.FundingSource.Balance
    end

  end
end
