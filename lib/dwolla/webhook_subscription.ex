defmodule Dwolla.WebhookSubscription do
  @moduledoc """
  Functions for `webhook-subscriptions` endpoint.
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
  @type params :: %{required(atom) => any}
  @type error :: HTTPoison.Error.t | Dwolla.Errors.t | tuple
  @type location :: %{id: String.t}

  @endpoint "webhook-subscriptions"

  @doc """
  Creates a webhook subscription.

  Parameters
  ```
  %{
    url: "http://myapplication.com/webhooks",
    secret: "s3cret"
  }
  ```
  """
  @spec create(token, map) :: {:ok, location} | {:error, error}
  def create(token, params) do
    headers = Utils.idempotency_header(params)
    Dwolla.make_request_with_token(:post, @endpoint, token, params, headers)
    |> Utils.handle_resp(:webhook_subscription)
  end

  @doc """
  Gets a webhook subscription by id.
  """
  @spec get(token, id) ::
    {:ok, Dwolla.WebhookSubscription.t} | {:error, error}
  def get(token, id) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:webhook_subscription)
  end

  @doc """
  Pauses a webhook subscription.
  """
  @spec pause(token, id) ::
    {:ok, Dwolla.WebhookSubscription.t} | {:error, error}
  def pause(token, id) do
    update(token, id, %{paused: true})
  end

  @doc """
  Resume a webhook subscription.
  """
  @spec resume(token, id) ::
    {:ok, Dwolla.WebhookSubscription.t} | {:error, error}
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
    {:ok, [Dwolla.WebhookSubscription.t]} | {:error, error}
  def list(token) do
    Dwolla.make_request_with_token(:get, @endpoint, token)
    |> Utils.handle_resp(:webhook_subscription)
  end

  @doc """
  Deletes a webhook subscription.
  """
  @spec delete(token, id) ::
    {:ok, Dwolla.WebhookSubscription.t} | {:error, error}
  def delete(token, id) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:delete, endpoint, token)
    |> Utils.handle_resp(:webhook_subscription)
  end

  @doc """
  Lists webhooks for a given webhook subscription.

  Parameters (optional)
  ```
  %{
    limit: 50,
    offset: 0
  }
  ```
  """
  @spec webhooks(token, id, params | nil) :: {:ok, [Dwolla.Webhook.t]} | {:error, error}
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
