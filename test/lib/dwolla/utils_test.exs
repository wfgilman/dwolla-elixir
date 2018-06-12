defmodule Dwolla.UtilsTest do

  use ExUnit.Case
  alias Dwolla.Utils

  describe "dwolla_utils" do

    test "handle_resp/2 handles parsing error" do
      payload = "<h1>Some XML payload</h1>"
      resp = success_resp(200, {:invalid, payload})

      assert {:error, body} = Utils.handle_resp(resp, :any)
      assert body == payload
    end
  end

  defp success_resp(code, body) do
    {:ok, %HTTPoison.Response{status_code: code, body: body}}
  end
end
