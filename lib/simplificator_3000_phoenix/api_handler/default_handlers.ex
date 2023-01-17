defmodule Simplificator3000Phoenix.ApiHandler.DefaultHandlers do
  import Simplificator3000Phoenix.Conn

  def default_response_handler(conn, response) do
    case response do
      {:ok, data} ->
        success_response(conn, data)

      {:ok, data, metadata} ->
        success_response(conn, data, metadata)

      {:error, error_options} ->
        error_response(conn, error_options)
    end
  end

  def default_invalid_params_handler(conn, params_error) do
    error_response(conn,
      reason: :invalid_params,
      response_status: 400,
      detail: params_error
    )
  end

  @default_show_full_error false
  def default_fallback_controller(conn, error, options) do
    options = options || []

    show_full_error = Keyword.get(options, :full_error, @default_show_full_error)

    if(show_full_error) do
      error_response(conn,
        reason: "internal server error",
        response_status: 500,
        detail: inspect(error)
      )
    else
      error_response(conn, reason: "internal server error", response_status: 500)
    end
  end

  def default_unauthorized_handler(conn) do
    conn
    |> Plug.Conn.send_resp(403, "Forbidden")
  end
end
