defmodule Dwolla.ErrorsTest do

  use ExUnit.Case

  import Dwolla.Factory

  setup do
    bypass = Bypass.open()
    Application.put_env(:dwolla, :root_uri, "http://localhost:#{bypass.port}/")
    {:ok, bypass: bypass}
  end

  describe "error" do

    test "400 response returns Dwolla.Error with formatted errors", %{bypass: bypass} do
      body = http_response_body(:error)
      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 400, Poison.encode!(body))
      end

      assert {:error, resp} = Dwolla.Customer.update("token", "id", %{})
      assert resp.__struct__ == Dwolla.Errors
      assert resp.errors == [
        %Dwolla.Errors.Error{
          code: "Required",
          message: "FirstName is required.",
          path: "/firstName"
        }
      ]
    end
  end
end
