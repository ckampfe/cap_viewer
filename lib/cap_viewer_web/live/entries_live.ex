defmodule CapViewerWeb.EntriesLive do
  use Phoenix.LiveView

  @sqlite_db_location Application.fetch_env!(:cap_viewer, :sqlite_db_location) |> String.to_charlist

  def render(assigns) do
    ~L"""
    <div>

      <button phx-click="reload">Reload</button>

      <button phx-click="flip-sort">Sort <%= if(@sort == "ASC", do: "DESC", else: "ASC") %></button>

      <form phx-change="search" style="float: right;">
        <input type="text" name="q" value="<%= @query %>" placeholder="Search..." />
      </form>
      </div>

    <div>

    <%= if @entries != %{} do %>
      <%= for {date, entries} <- @entries do %>
      <div>
        <h3><%= date %></h3>
          <%= for entry <- entries do %>
            <div>
              <%= render_entry(assigns, entry) %>
            </div>
            <hr />

          <% end %>
          <hr />
          </div>
      <% end %>
    <% else %>
      <h3>No entries</h3>
    <% end %>
    </div>
    """
  end

  def render_entry(assigns, entry) do
    ~L"""
    <div>
      <code>
        <span><%= entry[:created_at] %></span>
      </code>
      <div><%= entry[:body] %></div>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, entries} = fetch_entries(%{sort: "DESC", query: ""})
    {:ok, assign(socket, entries: entries, days: 10, sort: "DESC", query: "")}
  end

  def handle_event("reload", _path, socket) do
    opts = Enum.into(socket.assigns, %{})

    {:ok, entries} = fetch_entries(opts)

    {:noreply,
     assign(socket,
       entries: entries,
       sort: socket.assigns[:sort],
       days: socket.assigns[:days],
       query: socket.assigns[:query]
     )}
  end

  def handle_event("flip-sort", _path, socket) do
    new_sort =
      if socket.assigns[:sort] == "ASC" do
        "DESC"
      else
        "ASC"
      end

    opts =
      socket.assigns
      |> Enum.into(%{})
      |> Map.put(:sort, new_sort)

    {:ok, entries} = fetch_entries(opts)

    {:noreply, assign(socket, entries: entries, sort: new_sort, query: socket.assigns[:query])}
  end

  def handle_event("search", %{"q" => query}, socket) do
    {:ok, entries} = fetch_entries(%{sort: socket.assigns[:sort], query: query})
    {:noreply, assign(socket, entries: entries, query: query)}
  end

  def fetch_entries(%{query: query, sort: sort}) do
    {:ok, entries} =
      Sqlitex.with_db(@sqlite_db_location, fn db ->
        Sqlitex.query(
          db,
          "SELECT body, date(created_at) as date, created_at
          FROM entries
        #{
            if(query != "" && query != nil,
              do: "WHERE body LIKE \"%" <> query <> "%\"",
              else: ""
            )
          }
        ORDER BY created_at #{sort}
        ;",
          into: %{}
        )
      end)

    {:ok, group_entries_by_date(entries)}
  end

  def group_entries_by_date(entries) do
    Enum.group_by(entries, fn entry ->
      entry[:date]
    end)
  end
end
