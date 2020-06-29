defmodule Dwolla.Customer do
  @moduledoc """
  Functions for `customers` endpoint.
  """

  alias Dwolla.Utils

  defstruct id: nil, first_name: nil, last_name: nil, email: nil, type: nil,
            status: nil, created: nil, address1: nil, address2: nil, city: nil,
            phone: nil, postal_code: nil, state: nil

  @type t :: %__MODULE__{id: String.t,
                         first_name: String.t,
                         last_name: String.t,
                         email: String.t,
                         type: String.t,   # "unverified" | "personal" | "business" | "receive-only"
                         status: String.t, # "unverified" | "suspended" | "retry" | "document" | "verified" | "suspended"
                         created: String.t,
                         address1: String.t,
                         address2: String.t,
                         city: String.t,
                         phone: String.t,
                         postal_code: String.t,
                         state: String.t
                         }
  @type token :: String.t
  @type id :: String.t
  @type params :: %{required(atom) => String.t | integer}
  @type error :: HTTPoison.Error.t | Dwolla.Errors.t | atom | tuple
  @type location :: %{id: String.t}

  @endpoint "customers"

  @unverified_customer ["first_name", "last_name", "email"]

  @verified_customer   @unverified_customer ++ ["type", "address1", "city",
                       "state", "postal_code", "date_of_birth", "ssn"]

  @verify              ["first_name", "last_name", "email", "type", "address1",
                        "city", "state", "postal_code", "date_of_birth", "ssn",
                        "phone"]

  @doc """
  Creates an unverified customer.

  Validates payload for required fields before calling Dwolla API.

  Parameters
  ```
  %{first_name: "Steve", last_name: "Rogers", email: "cap@example.com"}
  ```
  """
  @spec create_unverified(token, params) :: {:ok, location} | {:error, error}
  def create_unverified(token, params) do
    case Utils.validate_params(params, @unverified_customer) do
      :ok    -> create(token, params)
      :error -> {:error, :invalid_parameters}
    end
  end

  @doc """
  Creates a verified customer.

  Validates payload for required fields before calling Dwolla API.

  Parameters
  ```
  %{
    first_name: "Steve",
    last_name: "Rogers",
    email: "cap@example.com",
    type: "personal",
    address1: "1600 Pennsylvania Ave",
    city: "Washington",
    state: "DC",
    postal_code: "20500",
    date_of_birth: "1918-07-04",
    ssn: "1776"
  }
  ```
  """
  @spec create_verified(token, params) :: {:ok, location} | {:error, error}
  def create_verified(token, params) do
    case Utils.validate_params(params, @verified_customer) do
      :ok    -> create(token, params)
      :error -> {:error, :invalid_parameters}
    end
  end

  @doc """
  Creates a customer.

  See `Dwolla.Customer.create_unverified/2` and `Dwolla.Customer.create_verified/2`.
  """
  @spec create(token, params) :: {:ok, location} | {:error, error}
  def create(token, params) do
    headers = Utils.idempotency_header(params)
    Dwolla.make_request_with_token(:post, @endpoint, token, params, headers)
    |> Utils.handle_resp(:customer)
  end

  @doc """
  Updates a customer's metadata.
  """
  @spec update(token, id, params) :: {:ok, Dwolla.Customer.t} | {:error, error}
  def update(token, id, params) do
    endpoint = @endpoint <> "/#{id}"
    headers = Utils.idempotency_header(params)
    Dwolla.make_request_with_token(:post, endpoint, token, params, headers)
    |> Utils.handle_resp(:customer)
  end

  @doc """
  Updates a customer to `verified` status.

  Parameters
  ```
  %{
    first_name: "Steve",
    last_name: "Rogers",
    email: "cap@example.com",
    address1: "1600 Pennsylvania Ave",
    city: "Washington",
    state: "DC",
    postal_code: "20500",
    date_of_birth: "1918-07-04",
    ssn: "1776"
  }
  ```
  """
  @spec verify(token, id, params) :: {:ok, Dwolla.Customer.t} | {:error, error}
  def verify(token, id, params) do
    case Utils.validate_params(params, @verify) do
      :ok    -> update(token, id, params)
      :error -> {:error, :invalid_parameters}
    end
  end

  @doc """
  Suspends a customer.
  """
  @spec suspend(token, id) :: {:ok, Dwolla.Customer.t} | {:error, error}
  def suspend(token, id) do
    update(token, id, %{status: "suspended"})
  end

  @doc """
  Searches customer by first name, last name and email. Results paginated.

  Parameters (optional)
  ```
  %{limit: 50, offset: 0, search: "Steve"}
  ```
  """
  @spec search(token, params) :: {:ok, [Dwolla.Customer.t]} | {:error, error}
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
  @spec get(token, id) :: {:ok, Dwolla.Customer.t} | {:error, error}
  def get(token, id) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:customer)
  end

  @doc """
  Creates a customer funding source.

  Parameters
  ```
  %{
    routing_number: "222222226",
    account_number: "123456789",
    type: "checking",
    name: "Ben's checking"
  }
  ```
  """
  @spec create_funding_source(token, id, params) :: {:ok, location} | {:error, error}
  def create_funding_source(token, id, params) do
    endpoint = @endpoint <> "/#{id}/funding-sources"
    headers = Utils.idempotency_header(params)
    Dwolla.make_request_with_token(:post, endpoint, token, params, headers)
    |> Utils.handle_resp(:funding_source)
  end

  @doc """
  Lists a customer's funding sources.
  """
  @spec list_funding_sources(token, id, boolean) :: {:ok, [Dwolla.FundingSource.t]} | {:error, error}
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

  Parameters
  ```
  %{startDate: "2017-04-01", endDate: "2017-04-30", status: "pending"}
  ```
  """
  @spec search_transfers(token, id, params) :: {:ok, [Dwolla.Transfer.t]} | {:error, error}
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
