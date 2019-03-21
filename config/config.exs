# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :cap_viewer, CapViewerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "DWFXkxi7Ik+dYByy3zphuD9lcKN+5TlVPAOqXSfbQg9+Nui3WpdRYWT/+LrzLqlc",
  render_errors: [view: CapViewerWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: CapViewer.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "cRPVteqyiC63iaeoQJXrWJAml2wYnLYZ"
  ]

config :cap_viewer,
  sqlite_db_location: "/Users/clark/cap.db"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# live view
config :phoenix,
  template_engines: [leex: Phoenix.LiveView.Engine]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
