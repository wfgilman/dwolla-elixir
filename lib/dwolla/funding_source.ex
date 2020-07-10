defmodule Dwolla.FundingSource do
  @moduledoc """
  Functions for `funding-sources` endpoint.
  """

  alias Dwolla.Utils

  defstruct id: nil, created: nil, name: nil, removed: false, status: nil,
            type: nil, channels: [], bank_name: nil, bank_account_type: nil

  @type t :: %__MODULE__{id: String.t,
                         created: String.t,
                         name: String.t,
                         removed: boolean,
                         status: String.t, # "verified" | "unverified"
                         type: String.t, # "bank" | "balance"
                         channels: [String.t],
                         bank_name: String.t,
                         bank_account_type: String.t
                         }
  @type token :: String.t
  @type id :: String.t
  @type error :: HTTPoison.Error.t | Dwolla.Errors.t | tuple

  @endpoint "funding-sources"

  defmodule Balance do
    @moduledoc """
    Dwolla Funding Source Balance data structure.
    """

    defstruct value: nil, currency: nil, last_updated: nil
    @type t :: %__MODULE__{value: String.t,
                           currency: String.t,
                           last_updated: String.t
                          }
  end

  @doc """
  Gets a funding source by id.
  """
  @spec get(token, id) :: {:ok, Dwolla.FundingSource.t} | {:error, error}
  def get(token, id) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:funding_source)
  end

  @doc """
  Updates the name of a funding source.
  """
  @spec update_name(token, id, String.t) :: {:ok, Dwolla.FundingSource.t} | {:error, error}
  def update_name(token, id, name) do
    update(token, id, %{name: name})
  end

  @doc """
  Removes a funding source.
  """
  @spec remove(token, id) :: {:ok, Dwolla.FundingSource.t} | {:error, error}
  def remove(token, id) do
    update(token, id, %{removed: true})
  end

  defp update(token, id, params) do
    endpoint = @endpoint <> "/#{id}"
    headers = Utils.idempotency_header(params)
    Dwolla.make_request_with_token(:post, endpoint, token, params, headers)
    |> Utils.handle_resp(:funding_source)
  end

  @doc """
  Gets the balance of a funding source.
  """
  @spec balance(token, id) :: {:ok, Dwolla.FundingSource.Balance.t} | {:error, error}
  def balance(token, id) do
    endpoint = @endpoint <> "/#{id}/balance"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:balance)
  end

end
