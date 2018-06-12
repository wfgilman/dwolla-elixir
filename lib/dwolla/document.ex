defmodule Dwolla.Document do
  @moduledoc """
  Functions for working with Dwolla Documents.
  """

  alias Dwolla.Utils

  defstruct id: nil, type: nil, status: nil, created: nil, failureReason: nil

  @type t :: %__MODULE__{id: String.t,
                         type: String.t,   # passport | license | idCard | other
                         status: String.t, # pending | reviewed
                         created: String.t,
                         failureReason: String.t

                   }
  @type token :: String.t
  @type id :: String.t
  @type error_msg :: map | list

  @endpoint "documents"

  @headers %{
    "Cache-Control" => "no-cache",
    "Content-Type" => "multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW"
  }

  @doc """
  Upload a document for a customer.
  """
  @spec create(token, id, String.t, String.t) :: {:ok, map} | {:error, error_msg}
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
  @spec list(token, id) :: {:ok, [Dwolla.Document.t]} | {:error, error_msg}
  def list(token, customer_id) do
    endpoint = "customers/#{customer_id}/#{@endpoint}"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:document)
  end

  @doc """
  Get a document.
  """
  @spec get(token, id) :: {:ok, Dwolla.Document.t} | {:error, error_msg}
  def get(token, id) do
    endpoint = @endpoint <> "/#{id}"
    Dwolla.make_request_with_token(:get, endpoint, token)
    |> Utils.handle_resp(:document)
  end
end
