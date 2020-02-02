defmodule CapViewerWeb.EntriesLive do
  use Phoenix.LiveView

  @sqlite_db_location Application.fetch_env!(:cap_viewer, :sqlite_db_location)
                      |> String.to_charlist()

  @tick_time :timer.minutes(1)

  def render(assigns) do
    ~L"""
    <div>
      <%= @uptime %>

      <%= for per <- [10, 25, 50, 100, "all"] do %>
        <a phx-click="per-page-<%= per %>" href="#"><%= per %></a>
      <% end %>

      <div class="container">
        <div class="row" style="display: flex; align-items: center; margin-bottom: 1.0rem;">

          <div class="column column-40">
            <button phx-click="reload" style="margin-bottom: 0;">Reload</button>
            <button phx-click="flip-sort" style="margin-bottom: 0;">
              Sort <%= if(@sort == "ASC", do: "DESC", else: "ASC") %>
            </button>
          </div>

          <div class="column column-20">Total entries: <%= @total_entries[:entries_count] %></div>

          <div class="column column-4" style="margin-left: auto;">
            <form phx-change="search" style="margin-bottom: 0;">
              <input type="text" name="q" value="<%= @query %>" placeholder="Search..." style="margin-bottom: 0;"/>
            </form>
          </div>

          <div class="column">
            <%= if @query_time_usec do %>
            <h6 style="margin: auto;">
              <%= @query_time_usec %> µsec
            </h6>
            <% end %>
          </div>

        </div>
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
            </div>
          <% end %>
        <% else %>
          <h3>No entries</h3>
        <% end %>
      </div>
    </div>
    """
  end

  def render_entry(assigns, entry) do
    ~L"""
    <div>
      <code>
        <span><%= entry[:created_at] %> UTC</span>
      </code>
      <div><%= entry[:body] %></div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    sort = "DESC"
    per_page = "25"

    {query_time_usec, {:ok, entries}} =
      :timer.tc(fn -> fetch_entries(%{sort: sort, query: "", per_page: per_page}) end)

    {:ok, total_entries} = fetch_entries_count()

    :timer.send_interval(@tick_time, self(), :tick)

    {:ok,
     assign(socket,
       entries: entries,
       days: 10,
       sort: sort,
       query: "",
       query_time_usec: query_time_usec,
       uptime: uptime(),
       per_page: per_page,
       total_entries: total_entries
     )}
  end

  def handle_info(:tick, socket) do
    uptime = uptime()
    {:ok, total_entries} = fetch_entries_count()
    {:noreply, assign(socket, uptime: uptime, total_entries: total_entries)}
  end

  def handle_event("per-page-" <> per_page, _path, socket) do
    opts =
      socket.assigns
      |> Enum.into(%{})
      |> Map.put(:per_page, per_page)

    {query_time_usec, {:ok, entries}} = :timer.tc(fn -> fetch_entries(opts) end)

    {:noreply,
     assign(socket, per_page: per_page, entries: entries, query_time_usec: query_time_usec)}
  end

  def handle_event("reload", _path, socket) do
    opts = Enum.into(socket.assigns, %{})

    {:ok, total_entries} = fetch_entries_count()

    {query_time_usec, {:ok, entries}} = :timer.tc(fn -> fetch_entries(opts) end)

    {:noreply,
     assign(socket,
       entries: entries,
       sort: socket.assigns[:sort],
       days: socket.assigns[:days],
       query: socket.assigns[:query],
       query_time_usec: query_time_usec,
       total_entries: total_entries
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

    {query_time_usec, {:ok, entries}} = :timer.tc(fn -> fetch_entries(opts) end)

    {:noreply,
     assign(socket,
       entries: entries,
       sort: new_sort,
       query: socket.assigns[:query],
       query_time_usec: query_time_usec
     )}
  end

  def handle_event("search", %{"q" => query}, socket) do
    opts =
      socket.assigns
      |> Enum.into(%{})
      |> Map.put(:query, query)

    {query_time_usec, {:ok, entries}} = :timer.tc(fn -> fetch_entries(opts) end)

    {:noreply, assign(socket, entries: entries, query: query, query_time_usec: query_time_usec)}
  end

  def fetch_entries(%{query: where, sort: sort, per_page: per_page}) do
    query_with_wildcards =
      if where do
        "%" <> where <> "%"
      else
        "%%"
      end

    {query, bindings} =
      if per_page != "all" do
        {"SELECT body, date(created_at) as date, created_at
          FROM entries
          WHERE body LIKE ?1
          ORDER BY created_at #{sort}
          LIMIT ?2;", [query_with_wildcards, per_page]}
      else
        {"SELECT body, date(created_at) as date, created_at
          FROM entries
          WHERE body LIKE ?1
          ORDER BY created_at #{sort};", [query_with_wildcards]}
      end

    {:ok, entries} =
      Sqlitex.with_db(@sqlite_db_location, fn db ->
        Sqlitex.query(
          db,
          query,
          into: %{},
          bind: bindings
        )
      end)

    {:ok, group_entries_by_date(entries, sort)}
  end

  def fetch_entries_count() do
    query = "SELECT COUNT(*) as entries_count FROM entries"

    {:ok, [total_count]} =
      Sqlitex.with_db(@sqlite_db_location, fn db ->
        Sqlitex.query(
          db,
          query,
          into: %{}
        )
      end)

    {:ok, total_count}
  end

  def group_entries_by_date(entries, sort) do
    grouped =
      Enum.group_by(entries, fn entry ->
        entry[:date]
      end)

    greater_than_or_equal = MapSet.new([:gt, :eq])

    if sort == "ASC" do
      Enum.sort(grouped)
    else
      Enum.sort_by(
        grouped,
        fn {date, _entries} ->
          Date.from_iso8601!(date)
        end,
        fn d1, d2 ->
          MapSet.member?(greater_than_or_equal, Date.compare(d1, d2))
        end
      )
    end
  end

  def uptime() do
    # http://erlang.org/pipermail/erlang-questions/2010-March/050079.html
    {uptime, _} = :erlang.statistics(:wall_clock)
    {days, {hours, minutes, seconds}} = :calendar.seconds_to_daystime(div(uptime, 1000))
    "#{days} days, #{hours} hours, #{minutes} minutes and #{seconds} seconds"
  end
end
