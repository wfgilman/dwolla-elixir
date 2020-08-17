defmodule Dwolla do
  @moduledoc """
  An HTTP Client for Dwolla.

  [Dwolla API Docs](https://docsv2.dwolla.com)
  """

  use HTTPoison.Base

  alias Dwolla.Utils

  @token_endpoint "token"

  defmodule MissingClientSecretError do
    defexception message: """
                 Client secret is missing. Please add client_id to your config.exs file.

                 config :dwolla, client_id: "your_client_id"
                 """
  end

  defmodule MissingClientIdError do
    defexception message: """
                 Client Id is missing. Please add client_secret to your config.exs file.

                 config :dwolla, client_secret: "your_client_secret"
                 """
  end

  defmodule MissingRootUriError do
    defexception message: """
                 The root_uri is required to specify the Dwolla environment to which you are
                 making calls, i.e. development or production. Please configure
                 root_uri in your config.exs file.

                 config :dwolla, root_uri: "https://api-sandbox.dwolla.com/" (development)
                 config :dwolla, root_uri: "https://api.dwolla.com/" (production)
                 """
  end

  @doc """
  Gets credentials from configuration.
  """
  @spec get_cred() :: map | no_return
  def get_cred do
    require_dwolla_credentials()
  end

  @doc """
  Gets root URI from configuration.
  """
  @spec get_root_uri() :: String.t() | no_return
  def get_root_uri do
    require_root_uri()
  end

  @doc """
  Makes request with token.
  """
  @spec make_request_with_token(atom, String.t(), String.t(), map, map, Keyword.t()) ::
          {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t() | {:invalid, binary}}
  def make_request_with_token(method, endpoint, token, body \\ %{}, headers \\ %{}, options \\ []) do
    rb = body |> Utils.to_camel_case() |> maybe_encode()
    rh = token |> get_request_headers() |> Map.merge(headers) |> Map.to_list()
    options = httpoison_request_options() ++ options
    request(method, endpoint, rb, rh, options)
  end

  defp maybe_encode({:multipart, _} = body), do: body
  defp maybe_encode(body), do: Poison.encode!(body)

  @doc """
  Makes request to OAuth endpoint with credentials.
  """
  @spec make_oauth_token_request(map, map, list) ::
          {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  def make_oauth_token_request(params, cred, options \\ []) do
    rb = Utils.encode_params(params, cred)
    rh = cred |> get_request_headers() |> Map.to_list()
    options = httpoison_request_options() ++ options
    request(:post, @token_endpoint, rb, rh, options)
  end

  def process_url(endpoint) do
    require_root_uri() <> endpoint
  end

  def process_response_body(""), do: ""

  def process_response_body(body) do
    case Poison.decode(body) do
      {:ok, parsed_body} -> parsed_body
      {:error, _} -> {:invalid, body}
    end
  end

  defp get_request_headers(%{client_id: client_id, client_secret: client_secret}) do
    encoded_auth_params = Base.encode64("#{client_id}:#{client_secret}")

    Map.new()
    |> Map.put("Authorization", "Bearer #{encoded_auth_params}")
    |> Map.put("Content-Type", "application/x-www-form-urlencoded")
  end

  defp get_request_headers(access_token) do
    Map.new()
    |> Map.put("Authorization", "Bearer #{access_token}")
    |> Map.put("Accept", "application/vnd.dwolla.v1.hal+json")
    |> Map.put("Content-Type", "application/vnd.dwolla.v1.hal+json")
  end

  defp require_dwolla_credentials do
    case {get_client_id(), get_client_secret()} do
      {:not_found, _} ->
        raise MissingClientIdError

      {_, :not_found} ->
        raise MissingClientSecretError

      {client_id, client_secret} ->
        %{client_id: client_id, client_secret: client_secret}
    end
  end

  defp require_root_uri do
    case Application.get_env(:dwolla, :root_uri) || :not_found do
      :not_found -> raise MissingRootUriError
      value -> value
    end
  end

  defp httpoison_request_options do
    Application.get_env(:dwolla, :httpoison_options, [])
  end

  defp get_client_id do
    Application.get_env(:dwolla, :client_id) || :not_found
  end

  defp get_client_secret do
    Application.get_env(:dwolla, :client_secret) || :not_found
  end
end
