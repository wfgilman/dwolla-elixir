defmodule Dwolla.WebhookSubscriptionTest do

  use ExUnit.Case

  import Dwolla.Factory

  alias Dwolla.WebhookSubscription
  alias Plug.Conn

  setup do
    bypass = Bypass.open()
    Application.put_env(:dwolla, :root_uri, "http://localhost:#{bypass.port}/")
    {:ok, bypass: bypass}
  end

  describe "webhook-subscriptions" do

    test "create/2 requests POST and returns a new id", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert "POST" == conn.method
        {k, v} = http_response_header(:webhook_subscription)
        conn
        |> Conn.put_resp_header(k, v)
        |> Conn.resp(201, "")
      end

      params = %{
        url: "https://twopence.co/api/dwolla",
        secret: "s3cret"
      }

      assert {:ok, resp} = WebhookSubscription.create("token", params)
      assert resp.id == "d2b4f94a-e0bf-4ef0-9285-a08efe023a4e"
    end

    test "get/2 requests GET and returns Dwolla.WebhookSubscription", %{bypass: bypass} do
      body = http_response_body(:webhook_subscription, :get)
      Bypass.expect bypass, fn conn ->
        assert "GET" == conn.method
        Conn.resp(conn, 200, body)
      end

      assert {:ok, resp} = WebhookSubscription.get("token", "id")
      assert resp.__struct__ == Dwolla.WebhookSubscription
      refute resp.id == nil
      refute resp.created == nil
      refute resp.url == nil
      refute resp.paused == nil
    end

    test "pause/2 requests POST and returns Dwolla.WebhookSubscription", %{bypass: bypass} do
      body = http_response_body(:webhook_subscription, :get)
      Bypass.expect bypass, fn conn ->
        assert "POST" == conn.method
        Conn.resp(conn, 200, body)
      end

      assert {:ok, resp} = WebhookSubscription.pause("token", "id")
      assert resp.__struct__ == Dwolla.WebhookSubscription
    end

    test "resume/2 requests POST and returns Dwolla.WebhookSubscription", %{bypass: bypass} do
      body = http_response_body(:webhook_subscription, :get)
      Bypass.expect bypass, fn conn ->
        assert "POST" == conn.method
        Conn.resp(conn, 200, body)
      end

      assert {:ok, resp} = WebhookSubscription.resume("token", "id")
      assert resp.__struct__ == Dwolla.WebhookSubscription
    end

    test "list/1 requests GET and returns list of Dwolla.WebhookSubscription", %{bypass: bypass} do
      body = http_response_body(:webhook_subscription, :list)
      Bypass.expect bypass, fn conn ->
        assert "GET" == conn.method
        Conn.resp(conn, 200, body)
      end

      assert {:ok, resp} = WebhookSubscription.list("token")
      assert Enum.count(resp) == 1
      sub = List.first(resp)
      assert sub.__struct__ == Dwolla.WebhookSubscription
    end

    test "delete/2 requests DELETE and returns Dwolla.WebhookSubscription", %{bypass: bypass} do
      body = http_response_body(:webhook_subscription, :get)
      Bypass.expect bypass, fn conn ->
        assert "DELETE" == conn.method
        Conn.resp(conn, 200, body)
      end

      assert {:ok, resp} = WebhookSubscription.delete("token", "id")
      assert resp.__struct__ == Dwolla.WebhookSubscription
    end

  end

end
