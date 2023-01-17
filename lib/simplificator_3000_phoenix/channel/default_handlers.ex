defmodule Simplificator3000Phoenix.Channel.DefaultHandlers do
  import Simplificator3000Phoenix.Channel.ChannelHelpers

  def default_invalid_params_handler(socket_of_ref, params_error) do
    error_reply(socket_of_ref,
      reason: :invalid_params,
      response_status: 400,
      detail: params_error
    )
  end

  @default_show_full_error false
  @spec default_fallback_controller(
          {Pid, atom, binary, binary, binary} | Phoenix.Socket.t(),
          any,
          false | nil | keyword
        ) :: :ok | {:reply, {:error, {:binary, binary} | map}, Phoenix.Socket.t()}
  def default_fallback_controller(socket_of_ref, error, options) do
    options = options || []

    show_full_error = Keyword.get(options, :full_error, @default_show_full_error)

    if(show_full_error) do
      error_reply(socket_of_ref,
        reason: "internal server error",
        response_status: 500,
        detail: inspect(error)
      )
    else
      error_reply(socket_of_ref, reason: "internal server error", response_status: 500)
    end
  end

  def default_unauthorized_handler(socket_of_ref) do
    socket_of_ref
    |> error_reply(reason: "forbidden")
  end
end
