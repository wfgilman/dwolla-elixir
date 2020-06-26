defmodule Dwolla.Utils do
  @moduledoc """
  Utility functions.
  """

  require Logger

  @doc """
  Encodes HTTP request.
  """
  @spec encode_params(map, map) :: String.t()
  def encode_params(params, cred \\ %{}) do
    params
    |> Map.merge(cred)
    |> Map.to_list()
    |> Enum.map_join("&", fn x -> pair(x) end)
  end

  defp pair({key, value}) do
    param_name = to_string(key) |> URI.encode_www_form()

    param_value =
      cond do
        is_map(value) ->
          Poison.encode!(value)

        is_list(value) ->
          Enum.map_join(value, "|", fn x -> x end) |> URI.encode_www_form()

        true ->
          to_string(value) |> URI.encode_www_form()
      end

    "#{param_name}=#{param_value}"
  end

  @doc """
  Validates parameter payload against a list of required fields.
  """
  @spec validate_params(map, list) :: :ok | :error
  def validate_params(params, fields) do
    Map.keys(params)
    |> Enum.map(&to_string/1)
    |> do_validate_params(fields)
  end

  defp do_validate_params(_param_fields, []), do: :ok

  defp do_validate_params(param_fields, [field | t]) do
    case field in param_fields do
      true ->
        do_validate_params(param_fields, t)

      _ ->
        :error
    end
  end

  @doc """
  Converts keys in Dwolla response to Elixir-friendly snake case.
  """
  def to_snake_case(response) when is_binary(response), do: response

  def to_snake_case(response) when is_map(response) do
    response
    |> Map.to_list()
    |> Stream.map(fn {k, v} ->
      cond do
        is_map(v) ->
          {Recase.to_snake(k), to_snake_case(v)}

        is_list(v) ->
          {Recase.to_snake(k), Enum.map(v, &to_snake_case/1)}

        true ->
          {Recase.to_snake(k), v}
      end
    end)
    |> Enum.into(%{})
  end

  @doc """
  Converts request payload to Dwolla-friendly camel case.
  """
  def to_camel_case(payload) when is_map(payload) do
    payload
    |> Map.to_list()
    |> Stream.map(fn {k, v} -> {to_string(k), v} end)
    |> Stream.map(fn {k, v} ->
      if is_map(v) do
        {key_to_camel_case(k), to_camel_case(v)}
      else
        {key_to_camel_case(k), v}
      end
    end)
    |> Enum.into(%{})
  end

  def to_camel_case(payload) do
    payload
  end

  defp key_to_camel_case(k) when k in ["_links", "_embedded"] do
    k
  end

  defp key_to_camel_case(k) do
    Recase.to_camel(k)
  end

  @doc """
  Handles HTTP response from Dwolla.
  """
  @spec handle_resp({:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}, atom) ::
          {:ok, any} | {:error, HTTPoison.Error.t() | Dwolla.Errors.t() | any}
  def handle_resp({:ok, %{body: {:invalid, body}}}, _schema) do
    {:error, body}
  end

  def handle_resp({:ok, %{status_code: 200, body: %{"error" => _} = body}}, _schema) do
    {:error, %Dwolla.Errors{code: body["error"], message: body["error_description"]}}
  end

  def handle_resp({:ok, %{status_code: code, body: ""} = resp}, _schema) when code in 200..201 do
    {:ok, get_resource_id_from_headers(resp.headers)}
  end

  def handle_resp({:ok, %{status_code: code} = resp}, schema) when code in 200..201 do
    {:ok, map_body(resp.body, schema)}
  end

  def handle_resp({:ok, resp}, _schema) do
    {:error, format_error(resp.body)}
  end

  def handle_resp({:error, error}, _schema) do
    {:error, error}
  end

  defp map_body(%{"_embedded" => %{"customers" => customers}}, schema) do
    Enum.map(customers, &map_body(&1, schema))
  end

  defp map_body(%{"_embedded" => %{"funding-sources" => funding_sources}}, schema) do
    Enum.map(funding_sources, &map_body(&1, schema))
  end

  defp map_body(%{"_embedded" => %{"transfers" => transfers}}, schema) do
    Enum.map(transfers, &map_body(&1, schema))
  end

  defp map_body(%{"_embedded" => %{"webhook-subscriptions" => webhook_subs}}, schema) do
    Enum.map(webhook_subs, &map_body(&1, schema))
  end

  defp map_body(%{"_embedded" => %{"webhooks" => webhooks}}, schema) do
    Enum.map(webhooks, &map_body(&1, schema))
  end

  defp map_body(%{"_embedded" => %{"retries" => retries}}, schema) do
    Enum.map(retries, &map_body(&1, schema))
  end

  defp map_body(%{"_embedded" => %{"events" => events}}, schema) do
    Enum.map(events, &map_body(&1, schema))
  end

  defp map_body(%{"_embedded" => %{"documents" => documents}}, schema) do
    Enum.map(documents, &map_body(&1, schema))
  end

  defp map_body(body, :customer) do
    body
    |> to_snake_case()
    |> Poison.Decode.transform(%{as: %Dwolla.Customer{}})
  end

  defp map_body(body, :funding_source) do
    body
    |> to_snake_case()
    |> Poison.Decode.transform(%{as: %Dwolla.FundingSource{}})
  end

  defp map_body(%{"_links" => links} = body, :transfer) do
    transfer =
      body
      |> to_snake_case()
      |> Poison.Decode.transform(%{
        as: %Dwolla.Transfer{
          amount: %Dwolla.Transfer.Amount{},
          metadata: %Dwolla.Transfer.Metadata{}
        }
      })

    can_cancel = Map.has_key?(links, "cancel")
    [source_resource, source_resource_id] = get_transfer_source_from_body(body)
    [dest_resource, dest_resource_id] = get_transfer_destination_from_body(body)
    source_funding_source_id = get_transfer_source_funding_source_from_body(body)

    transfer
    |> Map.put(:source_resource, source_resource)
    |> Map.put(:source_resource_id, source_resource_id)
    |> Map.put(:dest_resource, dest_resource)
    |> Map.put(:dest_resource_id, dest_resource_id)
    |> Map.put(:source_funding_source_id, source_funding_source_id)
    |> Map.put(:can_cancel, can_cancel)
  end

  defp map_body(body, :event) do
    event =
      body
      |> to_snake_case()
      |> Poison.Decode.transform(%{as: %Dwolla.Event{}})

    resource = get_resource_from_body(body)
    %{event | resource: resource}
  end

  defp map_body(body, :webhook_subscription) do
    body
    |> to_snake_case()
    |> Poison.Decode.transform(%{as: %Dwolla.WebhookSubscription{}})
  end

  defp map_body(body, :webhook) do
    body
    |> to_snake_case()
    |> Poison.Decode.transform(%{
      as: %Dwolla.Webhook{
        attempts: [
          %Dwolla.Webhook.Attempt{
            request: %Dwolla.Webhook.Attempt.Request{},
            response: %Dwolla.Webhook.Attempt.Response{}
          }
        ]
      }
    })
  end

  defp map_body(body, :retry) do
    body
    |> to_snake_case()
    |> Poison.Decode.transform(%{as: %Dwolla.Webhook.Retry{}})
  end

  defp map_body(body, :failure) do
    body
    |> to_snake_case()
    |> Poison.Decode.transform(%{as: %Dwolla.Transfer.Failure{}})
  end

  defp map_body(%{"balance" => balance} = body, :balance) do
    body
    |> to_snake_case()
    |> Map.merge(to_snake_case(balance))
    |> Poison.Decode.transform(%{as: %Dwolla.FundingSource.Balance{}})
  end

  defp map_body(body, :token) do
    body
    |> to_snake_case()
    |> Poison.Decode.transform(%{as: %Dwolla.Token{}})
  end

  defp map_body(body, :document) do
    body
    |> to_snake_case()
    |> Poison.Decode.transform(%{as: %Dwolla.Document{}})
  end

  defp get_transfer_source_from_body(%{"_links" => %{"source" => %{"href" => url}}} = _body) do
    url
    |> String.split("/")
    |> Enum.take(-2)
  end

  defp get_transfer_destination_from_body(
         %{"_links" => %{"destination" => %{"href" => url}}} = _body
       ) do
    url
    |> String.split("/")
    |> Enum.take(-2)
  end

  defp get_transfer_source_funding_source_from_body(
         %{"_links" => %{"source-funding-source" => %{"href" => url}}} = _body
       ) do
    url
    |> String.split("/")
    |> List.last()
  end

  defp get_transfer_source_funding_source_from_body(_) do
    nil
  end

  defp get_resource_from_body(%{"_links" => %{"resource" => %{"href" => url}}} = _body) do
    url
    |> String.split("/")
    |> Enum.take(-2)
    |> List.first()
  end

  defp get_resource_id_from_headers(headers) do
    headers
    |> get_resource_from_headers()
    |> extract_id_from_resource()
  end

  defp get_resource_from_headers(headers) do
    headers |> Enum.find(fn {k, _} -> k == "Location" end)
  end

  defp extract_id_from_resource({"Location", resource}) do
    id = String.split(resource, "/") |> List.last()
    %{id: id}
  end

  defp format_error(%{"_embedded" => %{"errors" => errors}} = body) do
    new_errors = Enum.map(errors, &Map.take(&1, ["code", "message", "path"]))

    body
    |> Map.drop(["_embedded"])
    |> Map.put("errors", new_errors)
    |> format_error()
  end

  defp format_error(body) do
    body
    |> to_snake_case()
    |> Poison.Decode.transform(%{as: %Dwolla.Errors{errors: [%Dwolla.Errors.Error{}]}})
  end

  @doc """
  Creates a idempotency header with an MD5 hash of the parameters submitted or
  provided binary value.
  """
  @spec idempotency_header(map) :: map
  def idempotency_header(idempotency_key) when is_binary(idempotency_key) do
    Map.new()
    |> Map.put("Idempotency-Key", idempotency_key)
  end

  def idempotency_header(params) do
    Map.new()
    |> Map.put("Idempotency-Key", generate_idempotency_key(params))
  end

  defp generate_idempotency_key(params) do
    :crypto.hash(:md5, encode_params(params))
    |> Base.encode16()
    |> String.downcase()
  end
end
