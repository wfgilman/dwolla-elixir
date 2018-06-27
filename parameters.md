# Parameters

## Credentials

All requests require a valid access token. This token is the first argument of
all functions. Consult the Dwolla API docs for the exact TTL, but as of this writing
it is 1 hour.

The access token can be refreshed using `Dwolla.Token.get/0`, which
will generate a new access token using the credentials stored in the configuration.
These credentials can be overridden by passing them to `Dwolla.Token.get/1`.

## Payload

This library opts to accept function arguments as a single map containing multiple parameters
rather than each parameter as a function argument.

For example, when initiating a transfer, you would construct the following
map which you pass to `Dwolla.Transfer.initiate/2`:
```
params = %{
  _links: %{
    source: %{
      href: "https://api-sandbox.dwolla.com/funding-sources/10d4133e-b308-4646-b276-40d9d36def1c"
    },
    destination: %{
      href: "https://api-sandbox.dwolla.com/funding-sources/10d4133e-b308-4646-b276-40d9d36def1c"
    }
  },
  amount: %{
    value: 100.00,
    currency: "USD"
  }
}

{:ok, _} = Dwolla.Transfer.initiate("my-token", params)
```

This is opposed to passing in each payload item as a separate function argument:
```
{:ok, _} = Dwolla.Transfer.initiate(
  "my-token",
  "10d4133e-b308-4646-b276-40d9d36def1c",
  "9ece9660-aa34-41eb-80d7-0125d53b45e8",
  100.00
)
```

There are pros and cons of this approach.

#### Pros

- Library is flexible. No update is needed if Dwolla adds another key to the request
payload.
- Library is simpler; less code to maintain.

#### Cons

- Business logic burden falls back on the user to know what the payload requests must be.
- More difficult to validate request payloads.
