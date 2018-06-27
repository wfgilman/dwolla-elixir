defmodule Dwolla.Transfer do
  @moduledoc """
  Functions for `transfers` endpoint.
  """

  alias Dwolla.Utils

  defstruct id: nil, created: nil, status: nil, amount: nil, metadata: nil,
            source_resource: nil, source_resource_id: nil,
            source_funding_source_id: nil, dest_resource: nil,
            dest_resource_id: nil, can_cancel: false

  @type t :: %__MODULE__{id: String.t,
                         created: String.t,
                         status: String.t, # "pending" | "processed" | "cancelled" | "failed" | "reclaimed"
                         amount: Dwolla.Transfer.Amount.t,
                         metadata: Dwolla.Transfer.Metadata.t,
                         source_resource: String.t,
                         source_resource_id: String.t,
                         source_funding_source_id: String.t,
                         dest_resource: String.t,
                         dest_resource_id: String.t,
                         can_cancel: boolean
                        }

  @type token :: String.t
  @type id :: String.t
  @type params :: %{required(atom) => any}
  @type error :: HTTPoison.Error.t | Dwolla.Errors.t | tuple
  @type location :: %{id: String.t}

  @endpoint "transfers"

  defmodule Amount do
    @moduledoc """
    Dwolla Transfer Amount data structure.
    """

    defstruct value: nil, currency: nil
    @type t :: %__MODULE__{value: String.t, currency: String.t}
  end

  defmodule Metadata do
    @moduledoc """
    Dwolla Transfer Metatdata data structure.
    """

    defstruct vendor: nil, origin_trans_id: nil, title: nil, note: nil
    @type t :: %__MODULE__{vendor: String.t,
                           origin_trans_id: String.t,
                           title: String.t,
                           note: String.t
                          }
  end

  defmodule Failure do
    @moduledoc """
    Dwolla Transfer Failure data structure.
    """

    defstruct code: nil, description: nil
    @type t :: %__MODULE__{code: String.t, description: String.t}
  end

  @doc """
  Initiates a transfer.

  The parameters are verbose because of the many options available to the user
  for setting the source and destination of the funds in the `href` field.

  Parameters
  ```
  %{
    _links: %{
      source: %{
        href: "https://api-sandbox.dwolla.com/funding-sources/..."
      },
      destination: %{
        href: "https://api-sandbox.dwolla.com/funding-sources/..."
      }
    },
    amount: %{
      value: 100.00,
      currency: "USD"
    },
    metadata: %{
      vendor: "Acme Inc.",
      note: "Invoice #12314"
    }
  }
  ```
  """
  @spec initiate(token, params, any | nil) :: {:ok, location} | {:error, error}
  def initiate(token, params, idempotency_key \\ nil) do
    headers = Utils.idempotency_header(idempotency_key || params)
    Dwolla.make_request_with_token(:post, @endpoint, token, params, headers)
    |> Utils.handle_resp(:transfer)
  end

  @doc """
  Gets a transfer by id.
  """
  @spec get(token, id) :: {:ok, Dwolla.Transfer.t} | {:error, error}
  def get(token, id) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:transfer)
  end

  @doc """
  Gets reason for a transfer's failure.
  """
  @spec get_transfer_failure_reason(token, id) :: {:ok, Dwolla.Transfer.Failure} | {:error, error}
  def get_transfer_failure_reason(token, id) do
    endpoint = @endpoint <> "/#{id}/failure"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:failure)
  end

  @doc """
  Cancels a transfer.
  """
  @spec cancel(token, id) :: {:ok, Dwolla.Transfer.t} | {:error, error}
  def cancel(token, id) do
    endpoint = @endpoint <> "/#{id}"
    params = %{status: "cancelled"}
    headers = Utils.idempotency_header(params)
    Dwolla.make_request_with_token(:post, endpoint, token, params, headers)
    |> Utils.handle_resp(:transfer)
  end

end
