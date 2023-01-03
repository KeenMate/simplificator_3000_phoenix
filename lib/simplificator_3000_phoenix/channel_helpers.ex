defmodule Simplificator3000Phoenix.ChannelHelpers do
  import Phoenix.Channel, only: [reply: 2, push: 3]
  import Simplificator3000.MapHelpers, only: [camelize_map_keys: 1]

  def request_id(%{assigns: %{request_id: request_id}}) do
    request_id
  end

  def success(data \\ nil, opts \\ []) do
    response =
      %{
        data: data,
        request_id: Keyword.get(opts, :request_id),
        metadata: Keyword.get(opts, :metadata)
      }
      |> camelize_map_keys()

    {
      :ok,
      response
    }
  end

  @spec success_reply(Phoenix.Socket.t() | Phoenix.Channel.socket_ref(), any(), Keyword.t()) ::
          {:noreply, Phoenix.Socket.t()}
          | {:noreply, Phoenix.Socket.t(), timeout | :hibernate}
          | {:reply, Phoenix.Channel.reply(), Phoenix.Socket.t()}
          | {:stop, reason :: term(), Phoenix.Socket.t()}
          | {:stop, reason :: term(), Phoenix.Channel.reply(), Phoenix.Socket.t()}
          | :ok
  def success_reply(socket, data \\ nil, opts \\ [])

  def success_reply(%Phoenix.Socket{} = socket, data, opts) do
    response = success(data, add_fallback_request_id(opts, socket))

    {:reply, response, socket}
  end

  def success_reply(ref, data, opts) do
    reply(ref, success(data, opts))
  end

  def success_push(socket, event, data \\ nil, opts \\ []) do
    response =
      %{
        status: "ok",
        data: data,
        request_id: Keyword.get(opts, :request_id),
        metadata: Keyword.get(opts, :metadata)
      }
      |> camelize_map_keys()

    push(
      socket,
      event,
      response
    )
  end

  def error(opts \\ []) do
    response =
      %{
        error: %{
          code: Keyword.get(opts, :reason),
          msg: Keyword.get(opts, :msg),
          detail: Keyword.get(opts, :detail)
        },
        request_id: Keyword.get(opts, :request_id),
        metadata: Keyword.get(opts, :metadata)
      }
      |> camelize_map_keys()

    {
      :error,
      response
    }
  end

  @spec error_reply(Phoenix.Socket.t() | Phoenix.Channel.socket_ref(), Keyword.t()) ::
          {:noreply, Phoenix.Socket.t()}
          | {:noreply, Phoenix.Socket.t(), timeout | :hibernate}
          | {:reply, Phoenix.Channel.reply(), Phoenix.Socket.t()}
          | {:stop, reason :: term(), Phoenix.Socket.t()}
          | {:stop, reason :: term(), Phoenix.Channel.reply(), Phoenix.Socket.t()}
          | :ok
  def error_reply(socket, opts \\ [])

  def error_reply(%Phoenix.Socket{} = socket, opts) do
    response =
      opts
      |> add_fallback_request_id(socket)
      |> error()

    {:reply, response, socket}
  end

  def error_reply(ref, opts) do
    reply(ref, error(opts))
  end

  def error_push(socket, event, opts) do
    response =
      %{
        status: "error",
        error: %{
          code: Keyword.get(opts, :reason),
          msg: Keyword.get(opts, :msg),
          detail: Keyword.get(opts, :detail)
        },
        request_id: Keyword.get(opts, :request_id),
        metadata: Keyword.get(opts, :metadata)
      }
      |> camelize_map_keys()

    push(
      socket,
      event,
      response
    )
  end

  defp add_fallback_request_id(opts, socket) do
    opts ++ [request_id: request_id(socket)]
  end
end
