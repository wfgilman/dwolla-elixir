defmodule Dwolla.Webhook do
  @moduledoc """
  Functions for `webhooks` endpoint.
  """

  alias Dwolla.Utils

  defstruct id: nil, topic: nil, account_id: nil, event_id: nil,
            subscription_id: nil, attempts: nil

  @type t :: %__MODULE__{id: String.t,
                         topic: String.t,
                         account_id: String.t,
                         event_id: String.t,
                         subscription_id: String.t,
                         attempts: [Dwolla.Webhook.Attempt.t]
                        }

  @type token :: String.t
  @type id :: String.t
  @type error :: HTTPoison.Error.t | Dwolla.Errors.t | tuple
  @type location :: %{id: String.t}

  @endpoint "webhooks"

  defmodule Attempt do
    @moduledoc """
    Dwolla Webhook Attempt data structure.
    """

    defstruct id: nil, request: nil, response: nil
    @type t :: %__MODULE__{id: String.t,
                           request: Dwolla.Webhook.Attempt.Request.t,
                           response: Dwolla.Webhook.Attempt.Response.t
                          }

    defmodule Request do
      @moduledoc """
      Dwolla Webhook Attempt Request data structure.
      """

      defstruct timestamp: nil, url: nil, headers: [], body: nil
      @type t :: %__MODULE__{timestamp: String.t,
                             url: String.t,
                             headers: list,
                             body: String.t
                            }
    end

    defmodule Response do
      @moduledoc """
      Dwolla Webhook Attempt Response data structure.
      """

      defstruct timestamp: nil, headers: [], status_code: nil, body: nil
      @type t :: %__MODULE__{timestamp: String.t,
                             headers: list,
                             status_code: integer,
                             body: String.t
                            }
    end
  end

  defmodule Retry do
    @moduledoc """
    Dwolla Webhook Retry data structure.
    """

    defstruct id: nil, timestamp: nil
    @type t :: %__MODULE__{id: String.t, timestamp: String.t}
  end

  @doc """
  Gets a webhook by id.
  """
  @spec get(token, id) :: {:ok, Dwolla.Webhook.t} | {:error, error}
  def get(token, id) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:webhook)
  end

  @doc """
  Retries a webhooks by id.
  """
  @spec retry(token, id) :: {:ok, location} | {:error, error}
  def retry(token, id) do
    endpoint = @endpoint <> "/#{id}/retries"
    Dwolla.make_request_with_token(:post, endpoint, token)
    |> Utils.handle_resp(:webhook)
  end

  @doc """
  Gets webhook retries by id.
  """
  @spec list_retries(token, id) ::
    {:ok, [Dwolla.Webhook.Retry.t]} | {:error, error}
  def list_retries(token, id) do
    endpoint = @endpoint <> "/#{id}/retries"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:retry)
  end

end
