defmodule Dwolla.Webhook do
  @moduledoc """
  Functions for working with Dwolla webhooks.
  """

  alias Dwolla.Utils

  defstruct id: nil, topic: nil, accountId: nil, eventId: nil, subscriptionId: nil,
            attempts: nil

  @type t :: %__MODULE__{id: String.t,
                         topic: String.t,
                         accountId: String.t,
                         eventId: String.t,
                         subscriptionId: String.t,
                         attempts: [Dwolla.Webhook.Attempt.t]
                        }

  @type token :: String.t
  @type id :: String.t
  @type error_msg :: map | list

  @endpoint "webhooks"

  defmodule Attempt do
    @moduledoc false
    defstruct id: nil, request: nil, response: nil
    @type t :: %__MODULE__{id: String.t,
                           request: Dwolla.Webhook.Attempt.Request.t,
                           response: Dwolla.Webhook.Attempt.Response.t
                          }

    defmodule Request do
      @moduledoc false
      defstruct timestamp: nil, url: nil, headers: [], body: nil
      @type t :: %__MODULE__{timestamp: String.t,
                             url: String.t,
                             headers: list,
                             body: String.t
                            }
    end

    defmodule Response do
      @moduledoc false
      defstruct timestamp: nil, headers: [], statusCode: nil, body: nil
      @type t :: %__MODULE__{timestamp: String.t,
                             headers: list,
                             statusCode: integer,
                             body: String.t
                            }
    end
  end

  defmodule Retry do
    @moduledoc false
    defstruct id: nil, timestamp: nil
    @type t :: %__MODULE__{id: String.t, timestamp: String.t}
  end

  @doc """
  Gets a webhook by id.
  """
  @spec get(token, id) :: {:ok, Dwolla.Webhook.t} | {:error, error_msg}
  def get(token, id) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:webhook)
  end

  @doc """
  Retries a webhooks by id.
  """
  @spec retry(token, id) :: {:ok, map} | {:error, error_msg}
  def retry(token, id) do
    endpoint = @endpoint <> "/#{id}/retries"
    Dwolla.make_request_with_token(:post, endpoint, token)
    |> Utils.handle_resp(:webhook)
  end

  @doc """
  Gets webhook retries by id.
  """
  @spec list_retries(token, id) ::
    {:ok, [Dwolla.Webhook.Retry]} | {:error, error_msg}
  def list_retries(token, id) do
    endpoint = @endpoint <> "/#{id}/retries"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:retry)
  end

end
