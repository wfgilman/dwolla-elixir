defmodule Dwolla.WebhookSubscription do
  @moduledoc """
  Functions for working with Dwolla Webhook Subscriptions.
  """
  alias Dwolla.Utils

  defstruct id: nil, created: nil, url: nil, paused: false

  @type t :: %__MODULE__{id: String.t,
                         created: String.t,
                         url: String.t,
                         paused: boolean
                        }

  @type token :: String.t
  @type id :: String.t
  @type error_msg :: map | list

  @endpoint "webhook-subscriptions"

  @doc """
  Creates a webhook subscription.
  """
  @spec create(token, map) :: {:ok, map} | {:error, error_msg}
  def create(token, params) do
    headers = Utils.idempotency_header(params)
    Dwolla.make_request_with_token(:post, @endpoint, token, params, headers)
    |> Utils.handle_resp(:webhook_subscription)
  end

  @doc """
  Gets a webhook subscription by id.
  """
  @spec get(token, id) ::
    {:ok, Dwolla.WebhookSubscription.t} | {:error, error_msg}
  def get(token, id) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:webhook_subscription)
  end

  @doc """
  Pauses a webhook subscription.
  """
  @spec pause(token, id) ::
    {:ok, Dwolla.WebhookSubscription.t} | {:error, error_msg}
  def pause(token, id) do
    update(token, id, %{paused: true})
  end

  @doc """
  Resume a webhook subscription.
  """
  @spec resume(token, id) ::
    {:ok, Dwolla.WebhookSubscription.t} | {:error, error_msg}
  def resume(token, id) do
    update(token, id, %{paused: false})
  end

  defp update(token, id, params) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:post, endpoint, token, params)
    |> Utils.handle_resp(:webhook_subscription)
  end

  @doc """
  Lists webhook subscriptions.
  """
  @spec list(token) ::
    {:ok, [Dwolla.WebhookSubscription.t]} | {:error, error_msg}
  def list(token) do
    Dwolla.make_request_with_token(:get, @endpoint, token)
    |> Utils.handle_resp(:webhook_subscription)
  end

  @doc """
  Deletes a webhook subscription.
  """
  @spec delete(token, id) ::
    {:ok, Dwolla.WebhookSubscription.t} | {:error, error_msg}
  def delete(token, id) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:delete, endpoint, token)
    |> Utils.handle_resp(:webhook_subscription)
  end

  @doc """
  Lists webhooks for a given webhook subscription.
  """
  @spec webhooks(token, id) :: {:ok, [Dwolla.Webhook.t]} | {:error, error_msg}
  def webhooks(token, id, params \\ %{}) do
    endpoint =
      case Map.keys(params) do
        [] -> @endpoint <> "/#{id}/webhooks"
        _  -> @endpoint <> "/#{id}/webhooks?" <> Utils.encode_params(params)
      end
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:webhook)
  end
end
