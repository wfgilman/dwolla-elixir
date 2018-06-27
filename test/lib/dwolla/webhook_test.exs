defmodule Dwolla.WebhookTest do

  use ExUnit.Case

  import Dwolla.Factory

  alias Dwolla.Webhook
  alias Plug.Conn

  setup do
    bypass = Bypass.open()
    Application.put_env(:dwolla, :root_uri, "http://localhost:#{bypass.port}/")
    {:ok, bypass: bypass}
  end

  describe "webhook" do

    test "get/2 requests GET and returns Dwolla.Webhook", %{bypass: bypass} do
      body = http_response_body(:webhook, :get)
      Bypass.expect bypass, fn conn ->
        assert "GET" == conn.method
        Conn.resp(conn, 200, body)
      end

      assert {:ok, resp} = Webhook.get("token", "id")
      assert resp.__struct__ == Dwolla.Webhook
      refute resp.id == nil
      refute resp.topic == nil
      refute resp.account_id == nil
      refute resp.event_id == nil
      refute resp.subscription_id == nil
      assert Enum.count(resp.attempts) == 1
      attempt = List.first(resp.attempts)
      assert attempt.__struct__ == Dwolla.Webhook.Attempt
      refute attempt.id == nil
      assert attempt.request.__struct__ == Dwolla.Webhook.Attempt.Request
      refute attempt.request.timestamp == nil
      refute attempt.request.url == nil
      refute attempt.request.headers == []
      refute attempt.request.body == nil
      assert attempt.response.__struct__ == Dwolla.Webhook.Attempt.Response
      refute attempt.response.timestamp == nil
      refute attempt.response.headers == []
      refute attempt.response.status_code == nil
      refute attempt.response.body == nil
    end

    test "retry/2 requests POST and returns a new id", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert "POST" == conn.method
        {k, v} = http_response_header(:webhook)
        conn
        |> Conn.put_resp_header(k, v)
        |> Conn.resp(201, "")
      end

      assert {:ok, resp} = Webhook.retry("token", "id")
      assert resp.id == "5aa27a0f-cf99-418d-a3ee-67c0ff99a494"
    end

    test "list_retries/2 requests GET and returns list of Dwolla.Retry", %{bypass: bypass} do
      body = http_response_body(:webhook, :retries)
      Bypass.expect bypass, fn conn ->
        assert "GET" == conn.method
        Conn.resp(conn, 200, body)
      end

      assert {:ok, resp} = Webhook.list_retries("token", "id")
      assert Enum.count(resp) == 1
      retry = List.first(resp)
      assert retry.__struct__ == Dwolla.Webhook.Retry
      refute retry.id == nil
      refute retry.timestamp == nil
    end
  end

end
