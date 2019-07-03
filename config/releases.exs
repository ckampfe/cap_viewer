import Config

config :cap_viewer, CapViewerWeb.Endpoint,
  load_from_system_env: true,
  http: [:inet6, port: {:system, "PORT"} || 5000],
  url: [host: "localhost", port: {:system, "PORT"} || 5000],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:phoenix_distillery, :vsn)
