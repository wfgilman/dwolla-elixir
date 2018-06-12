defmodule Dwolla.Customer do
  @moduledoc """
  Functions for working with Dwolla Customers.
  """

  alias Dwolla.Utils

  defstruct id: nil, firstName: nil, lastName: nil, email: nil, type: nil,
            status: nil, created: nil, address1: nil, address2: nil, city: nil,
            phone: nil, postalCode: nil, state: nil

  @type t :: %__MODULE__{id: String.t,
                         firstName: String.t,
                         lastName: String.t,
                         email: String.t,
                         type: String.t, # "unverified" | "personal" | "business" | "recieve-only"
                         status: String.t, # "unverified" | "suspended" | "retry" | "document" | "verified" | "suspended"
                         created: String.t,
                         address1: String.t,
                         address2: String.t,
                         city: String.t,
                         phone: String.t,
                         postalCode: String.t,
                         state: String.t
                         }
  @type token :: String.t
  @type id :: String.t
  @type params :: map
  @type error_msg :: map | list

  @endpoint "customers"

  @unverified_customer ["firstName", "lastName", "email", "ipAddress"]

  @verified_customer   @unverified_customer ++ ["type", "address1", "city",
                        "state", "postalCode", "dateOfBirth", "ssn", "phone"]

  @verify               ["firstName", "lastName", "email", "type", "address1",
                         "city", "state", "postalCode", "dateOfBirth", "ssn",
                         "phone"]

  @doc """
  Creates an unverified customer.
  """
  @spec create_unverified(token, params) ::
    {:ok, map} | {:error, error_msg} | {:error, :invalid_parameters}
  def create_unverified(token, params) do
    case Utils.validate_params(params, @unverified_customer) do
      :ok    -> create(token, params)
      :error -> {:error, :invalid_parameters}
    end
  end

  @doc """
  Creates a verified customer.
  """
  @spec create_verified(token, params) ::
    {:ok, map} | {:error, error_msg} | {:error, :invalid_parameters}
  def create_verified(token, params) do
    case Utils.validate_params(params, @verified_customer) do
      :ok    -> create(token, params)
      :error -> {:error, :invalid_parameters}
    end
  end

  @doc """
  Creates a customer.
  """
  @spec create(token, params) :: {:ok, map} | {:error, error_msg}
  def create(token, params) do
    headers = Utils.idempotency_header(params)
    Dwolla.make_request_with_token(:post, @endpoint, token, params, headers)
    |> Utils.handle_resp(:customer)
  end

  @doc """
  Updates a customer's metadata.
  """
  @spec update(token, id, params) ::
    {:ok, Dwolla.Customer.t} | {:error, error_msg}
  def update(token, id, params) do
    endpoint = @endpoint <> "/#{id}"
    headers = Utils.idempotency_header(params)
    Dwolla.make_request_with_token(:post, endpoint, token, params, headers)
    |> Utils.handle_resp(:customer)
  end

  @doc """
  Updates a customer to verified status.
  """
  @spec verify(token, id, params) ::
    {:ok, Dwolla.Customer.t} | {:error, error_msg} | {:error, :invalid_parameters}
  def verify(token, id, params) do
    case Utils.validate_params(params, @verify) do
      :ok    -> update(token, id, params)
      :error -> {:error, :invalid_parameters}
    end
  end

  @doc """
  Suspends a customer.
  """
  @spec suspend(token, id) ::
    {:ok, Dwolla.Customer.t} | {:error, error_msg}
  def suspend(token, id) do
    update(token, id, %{status: "suspended"})
  end

  @doc """
  Searches customer by first name, last name and email. Results paginated.
  ```
  params = %{limit: 50, offset: 0, search: "ben@twopence.co"}
  ```
  """
  @spec search(token, params) ::
    {:ok, [Dwolla.Customer.t]} | {:ok, list} | {:error, error_msg}
  def search(token, params \\ %{}) do
    endpoint =
      case Map.keys(params) do
        [] -> @endpoint
        _  -> @endpoint <> "?" <> Utils.encode_params(params)
      end
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:customer)
  end

  @doc """
  Gets a customer by id.
  """
  @spec get(token, id) :: {:ok, Dwolla.Customer.t} | {:error, error_msg}
  def get(token, id) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:customer)
  end

  @doc """
  Creates a customer funding source.
  ```
  params = %{routingNumber: "222222226", accountNumber: "123456789",
             type: "checking", name: "Ben's checking"}
  ```
  """
  @spec create_funding_source(token, id, params) ::
    {:ok, map} | {:error, error_msg}
  def create_funding_source(token, id, params) do
    endpoint = @endpoint <> "/#{id}/funding-sources"
    headers = Utils.idempotency_header(params)
    Dwolla.make_request_with_token(:post, endpoint, token, params, headers)
    |> Utils.handle_resp(:funding_source)
  end

  @doc """
  Lists a customer's funding sources.
  """
  @spec list_funding_sources(token, id, boolean) ::
    {:ok, [Dwolla.FundingSource.t] | []} | {:error, error_msg}
  def list_funding_sources(token, id, removed \\ true) do
    endpoint =
      case removed do
        true  -> @endpoint <> "/#{id}/funding-sources"
        false -> @endpoint <> "/#{id}/funding-sources?removed=false"
      end
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:funding_source)
  end

  @doc """
  Searchs a customer's transfers. Results paginated.
  ```
  params = %{startDate: "2017-04-01", endDate: "2017-04-30", status: "pending"}
  ```
  """
  @spec search_transfers(token, id, params) ::
    {:ok, [Dwolla.Transfer.t] | []} | {:error, error_msg}
  def search_transfers(token, id, params \\ %{}) do
    endpoint =
      case Map.keys(params) do
        [] -> @endpoint <> "/#{id}/transfers"
        _  -> @endpoint <> "/#{id}/transfers?" <> Utils.encode_params(params)
      end
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:transfer)
  end

end
