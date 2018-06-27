defmodule Dwolla.Document do
  @moduledoc """
  Functions for `documents` endpoint.
  """

  alias Dwolla.Utils

  defstruct id: nil, type: nil, status: nil, created: nil, failure_reason: nil

  @type t :: %__MODULE__{id: String.t,
                         type: String.t,   # passport | license | idCard | other
                         status: String.t, # pending | reviewed
                         created: String.t,
                         failure_reason: String.t

                   }
  @type token :: String.t
  @type id :: String.t
  @type error :: HTTPoison.Error.t | Dwolla.Errors.t | tuple
  @type location :: %{id: String.t}

  @endpoint "documents"

  @headers %{
    "Cache-Control" => "no-cache",
    "Content-Type" => "multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW"
  }

  @doc """
  Upload a document for a customer.

  Accepted document type values:
  - `passport`
  - `license`
  - `idCard`
  - `other`
  """
  @spec create(token, id, String.t, String.t) :: {:ok, location} | {:error, error}
  def create(token, customer_id, document_type, file) do
    endpoint = "customers/#{customer_id}/#{@endpoint}"
    form = {:multipart, [
      {:file, file},
      {"documentType", document_type}
    ]}
    Dwolla.make_request_with_token(:post, endpoint, token, form, @headers)
    |> Utils.handle_resp(:document)
  end

  @doc """
  List a customer's documents.
  """
  @spec list(token, id) :: {:ok, [Dwolla.Document.t]} | {:error, error}
  def list(token, customer_id) do
    endpoint = "customers/#{customer_id}/#{@endpoint}"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:document)
  end

  @doc """
  Get a document.
  """
  @spec get(token, id) :: {:ok, Dwolla.Document.t} | {:error, error}
  def get(token, id) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:document)
  end
end
