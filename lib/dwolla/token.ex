defmodule Dwolla.Token do
  @moduledoc """
  Functions for Dwolla OAuth 2 endpoint.
  """

  defstruct access_token: nil, expires_in: nil, token_type: nil

  @type t :: %__MODULE__{access_token: String.t,
                         expires_in: integer,
                         token_type: String.t}
  @type cred :: map | nil
  @type error_msg :: map | list

  @doc """
  Gets an access token from Application credentials.
  """
  @spec get(map | nil) :: {:ok, Dwolla.Token.t} | {:error, error_msg}
  def get(cred \\ nil) do
    params = %{grant_type: "client_credentials"}
    Dwolla.make_oauth_token_request(params, cred || Dwolla.get_cred())
    |> Dwolla.Utils.handle_resp(:token)
  end

end
