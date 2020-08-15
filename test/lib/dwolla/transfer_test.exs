defmodule Dwolla.TransferTest do
  use ExUnit.Case

  import Dwolla.Factory

  alias Dwolla.Transfer
  alias Plug.Conn

  setup do
    bypass = Bypass.open()
    Application.put_env(:dwolla, :root_uri, "http://localhost:#{bypass.port}/")
    {:ok, bypass: bypass}
  end

  describe "transfer" do
    test "initiate/2 requests POST and returns a new id", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        assert "POST" == conn.method
        {k, v} = http_response_header(:transfer)

        conn
        |> Conn.put_resp_header(k, v)
        |> Conn.resp(201, "")
      end)

      params = %{
        _links: %{
          source: %{
            href: "https://api-uat.dwolla.com/funding-sources/sender-id"
          },
          destination: %{
            href: "https://api-uat.dwolla.com/funding-sources/recip-id"
          }
        },
        amount: %{
          currency: "USD",
          value: "25.60"
        }
      }

      assert {:ok, resp} = Transfer.initiate("token", params)
      assert resp.id == "494b6269-d909-e711-80ee-0aa34a9b2388"
    end

    test "get/2 requests GET and returns Dwolla.Transfer", %{bypass: bypass} do
      body = http_response_body(:transfer, :get)

      Bypass.expect(bypass, fn conn ->
        assert "GET" == conn.method
        Conn.resp(conn, 200, body)
      end)

      assert {:ok, resp} = Transfer.get("token", "id")
      assert resp.__struct__ == Dwolla.Transfer
      refute resp.id == nil
      refute resp.created == nil
      refute resp.status == nil
      refute resp.amount.value == nil
      refute resp.amount.currency == nil
      assert resp.metadata["customer_id"] == "1234"
      assert resp.metadata["notes"] == "First test transfer!"
      assert resp.correlation_id == "4293d107-fa46-4188-91b1-e60bb9621bea"
      assert resp.individual_ach_id == "IWOBPWJZ"
      assert resp.clearing.source == "standard"
      assert resp.clearing.destination == nil
      assert resp.source_resource == "accounts"
      assert resp.source_resource_id == "fc81fee0-1520-4949-bc2d-73e4e11fddd9"
      assert resp.source_funding_source_id == "70c99528-285d-4de5-9ece-6d9b8f5cb1a4"
      assert resp.dest_resource == "customers"
      assert resp.dest_resource_id == "df1eb2aa-3d75-48a1-b882-425b579a85dc"
      assert resp.dest_funding_source_id == "500f8e0e-dfd5-431b-83e0-cd6632e63fcb"
      assert resp.can_cancel == true
    end

    test "get_transfer_failure_reason/2 requests GET and returns Dwolla.Transfer.Failure", %{
      bypass: bypass
    } do
      body = http_response_body(:transfer, :failure)

      Bypass.expect(bypass, fn conn ->
        assert "GET" == conn.method
        Conn.resp(conn, 200, body)
      end)

      assert {:ok, resp} = Transfer.get_transfer_failure_reason("token", "id")
      assert resp.__struct__ == Dwolla.Transfer.Failure
      refute resp.code == nil
      refute resp.description == nil
    end

    test "cancel/2 requests POST and returns Dwolla.Transfer", %{bypass: bypass} do
      body = http_response_body(:transfer, :get)

      Bypass.expect(bypass, fn conn ->
        assert "POST" == conn.method
        Conn.resp(conn, 200, body)
      end)

      assert {:ok, resp} = Transfer.cancel("token", "id")
      assert resp.__struct__ == Dwolla.Transfer
    end
  end
end
