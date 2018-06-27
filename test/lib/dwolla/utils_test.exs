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

    test "to_snake_case/1 converts string keys to snake case" do
      params = %{
        "firstName" => "Steve",
        "lastName" => "Rogers",
        "dateOfBirth" => "1918-07-04",
        "amount" => %{
          "value" => 100.0,
          "currency" => "USD"
        }
      }

      assert Utils.to_snake_case(params) == %{
        "first_name" => "Steve",
        "last_name" => "Rogers",
        "date_of_birth" => "1918-07-04",
        "amount" => %{
          "value" => 100.0,
          "currency" => "USD"
        }
      }
    end

    test "to_camel_case/1 converts atom keys to camel case" do
      params = %{
        first_name: "Steve",
        last_name: "Rogers",
        date_of_birth: "1918-07-04",
        amount: %{
          value: 100.0,
          currency: "USD"
        }
      }

      assert Utils.to_camel_case(params) == %{
        "firstName" => "Steve",
        "lastName" => "Rogers",
        "dateOfBirth" => "1918-07-04",
        "amount" => %{
          "value" => 100.0,
          "currency" => "USD"
        }
      }
    end
  end

  defp success_resp(code, body) do
    {:ok, %HTTPoison.Response{status_code: code, body: body}}
  end
end
