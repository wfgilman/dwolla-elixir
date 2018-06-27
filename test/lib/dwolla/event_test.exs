defmodule Dwolla.EventTest do

  use ExUnit.Case

  import Dwolla.Factory

  alias Dwolla.Event
  alias Plug.Conn

  setup do
    bypass = Bypass.open()
    Application.put_env(:dwolla, :root_uri, "http://localhost:#{bypass.port}/")
    {:ok, bypass: bypass}
  end

  describe "events" do

    test "list/3 requests GET and returns list of Dwolla.Event", %{bypass: bypass} do
      body = http_response_body(:event, :list)
      Bypass.expect bypass, fn conn ->
        assert "GET" == conn.method
        Conn.resp(conn, 200, body)
      end

      assert {:ok, resp} = Event.list("token")
      assert Enum.count(resp) == 2
      event = List.first(resp)
      assert event.__struct__ == Dwolla.Event
    end

    test "list/3 sets only limit query string parameter", %{bypass: bypass} do
      body = http_response_body(:event, :list)
      Bypass.expect bypass, fn conn ->
        assert "limit=50" == conn.query_string
        Conn.resp(conn, 200, body)
      end

      Event.list("token", 50)
    end

    test "list/3 sets limit and offset query string parameters", %{bypass: bypass} do
      body = http_response_body(:event, :list)
      Bypass.expect bypass, fn conn ->
        assert "limit=50&offset=100" == conn.query_string
        Conn.resp(conn, 200, body)
      end

      Event.list("token", 50, 100)
    end

    test "get/2 requests GET and returns Dwolla.Event", %{bypass: bypass} do
      body = http_response_body(:event, :get)
      Bypass.expect bypass, fn conn ->
        assert "GET" == conn.method
        Conn.resp(conn, 200, body)
      end

      assert {:ok, resp} = Event.get("token", "id")
      assert resp.__struct__ == Dwolla.Event
      refute resp.created == nil
      refute resp.id == nil
      refute resp.resource_id == nil
      refute resp.topic == nil
    end

  end
end
