# Dwolla

[![Build Status](https://travis-ci.org/wfgilman/dwolla-elixir.svg?branch=master)](https://travis-ci.org/wfgilman/dwolla-elixir)
[![Hex.pm Version](https://img.shields.io/hexpm/v/dwolla_elixir.svg)](https://hex.pm/packages/dwolla_elixir)

Elixir Library for Dwolla

Supported endpoints:

- [ ] Accounts
- [x] Customers
- [x] Documents
- [x] Funding Sources
- [x] Transfers
- [ ] Mass Payments
- [x] Events
- [x] Webhook Subscriptions
- [x] Webhooks

[Dwolla Documentation](https://docsv2.dwolla.com)

## Usage

Add to your dependencies in `mix.exs`.

```elixir
def deps do
  [{:dwolla, "~> 1.0"}]
end
```

## Configuration

All calls to Dwolla require a valid access token. To fetch/refresh the access token
you need to add your Dwolla client_id and client_secret to your config.

```elixir
config :dwolla,
  root_uri: "https://api.dwolla.com/",
  client_id: "your_client_id",
  client_secret: "your_client_secret",
  access_token: nil,
  httpoison_options: [timeout: 10_000, recv_timeout: 10_000],
```

The `root_uri` is configured by `mix` environment by default. You
can override them in your configuration.

- `dev` - sandbox
- `prod` - production

You can also pass in a custom configuration for [HTTPoison](https://github.com/edgurgel/httpoison).

## Tests and Style

This library uses [bypass](https://github.com/PSPDFKit-labs/bypass) to simulate HTTP responses from Dwolla.

Run tests using `mix test`.

Before making pull requests, run the coverage and style checks.

```elixir
mix coveralls
mix credo
```
