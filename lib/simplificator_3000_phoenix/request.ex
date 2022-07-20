defmodule Simplificator3000Phoenix.Request do
  import Plug.Conn

  @spec request_ip(Plug.Conn.t()) :: binary
  def request_ip(conn) do
    conn.remote_ip
    |> :inet_parse.ntoa()
    |> to_string()
  end

  @spec user_agent(Plug.Conn.t()) :: binary | nil
  def user_agent(conn) do
    case get_req_header(conn, "user-agent") do
      [user_agent] -> user_agent
      _ -> nil
    end
  end

  @spec request_id() :: any
  def request_id() do
    Logger.metadata()[:request_id]
  end
end
