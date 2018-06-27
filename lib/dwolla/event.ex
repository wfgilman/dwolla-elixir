defmodule Dwolla.Event do
  @moduledoc """
  Functions for `events` endpoint.
  """

  alias Dwolla.Utils

  defstruct id: nil, created: nil, topic: nil, resource: nil, resource_id: nil

  @type t :: %__MODULE__{id: String.t,
                         created: String.t,
                         topic: String.t,
                         resource: String.t,
                         resource_id: String.t
                        }

  @type token :: String.t
  @type id :: String.t
  @type error :: HTTPoison.Error.t | Dwolla.Errors.t | tuple

  @endpoint "events"

  @doc """
  Lists events. Results paginated.
  """
  @spec list(token, integer | nil, integer | nil) :: {:ok, [Dwolla.Event.t]} | {:error, error}
  def list(token, limit \\ nil, offset \\ nil) do
    endpoint =
      case {limit, offset} do
        {nil, nil}    -> @endpoint
        {limit, nil}  -> "#{@endpoint}/?" <> Utils.encode_params(%{limit: limit})
        _             -> "#{@endpoint}/?" <> Utils.encode_params(%{limit: limit, offset: offset})
      end
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:event)
  end

  @doc """
  Gets a funding source by id.
  """
  @spec get(token, id) :: {:ok, Dwolla.Event.t} | {:error, error}
  def get(token, id) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:event)
  end
end
