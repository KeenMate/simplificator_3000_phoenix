defmodule Simplificator3000Phoenix.Channel.ChannelHelpers do
  alias Simplificator3000.RandomHelpers

  import Phoenix.Socket, only: [assign: 3]
  import Phoenix.Channel, only: [reply: 2, push: 3]
  import Simplificator3000.MapHelpers, only: [camel_cased_map_keys: 1]

  defguard is_ctx_related(ctx, socket) when ctx.user_id == socket.assigns.user.user_id

  def put_request_id(socket) do
    request_id = RandomHelpers.new_guid()
    #    Logger.debug("Generated new reqid for channel call: #{request_id}")
    socket
    |> assign(:request_id, request_id)
    |> case do
      %{assigns: %{ctx: ctx}} = socket ->
        assign(socket, :ctx, Map.put(ctx, :request_id, request_id))

      val ->
        val
    end
  end

  def request_id(%{assigns: %{request_id: request_id}}) do
    request_id
  end

  @spec success(any, keyword) :: map
  def success(data \\ nil, opts \\ []) do
    %{
      data: data,
      request_id: Keyword.get(opts, :request_id),
      metadata: Keyword.get(opts, :metadata)
    }
    |> camel_cased_map_keys()
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

    {:reply, {:ok, response}, socket}
  end

  def success_reply(ref, data, opts) do
    reply(ref, {:ok, success(data, opts)})
  end

  def success_push(socket, event, data \\ nil, opts \\ []) do
    response =
      success(data, opts)
      |> add_status("ok")

    push(
      socket,
      event,
      response
    )
  end

  def error(opts \\ []) do
    %{
      error: %{
        code: Keyword.get(opts, :reason),
        msg: Keyword.get(opts, :msg),
        detail: Keyword.get(opts, :detail)
      },
      request_id: Keyword.get(opts, :request_id),
      metadata: Keyword.get(opts, :metadata)
    }
    |> camel_cased_map_keys()
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

    {:reply, {:error, response}, socket}
  end

  def error_reply(ref, opts) do
    reply(ref, {:error, error(opts)})
  end

  def error_push(socket, event, opts) do
    response = error(opts) |> add_status("error")

    push(
      socket,
      event,
      response
    )
  end

  def user_id(socket) do
    get_user_key(socket, :user_id)
  end

  def username(socket) do
    get_user_key(socket, :username)
  end

  def get_user_key(socket, key) do
    socket
    |> user()
    |> Map.get(key)
  end

  def get_user_ctx(socket) do
    user_ctx(socket)
  end

  def get_identity(socket) do
    user(socket)
  end

  def user(%{assigns: %{user: user}}), do: user

  @spec user_ctx(Phoenix.Socket.t()) :: UserContext.t()
  def user_ctx(%{assigns: %{ctx: ctx}}), do: ctx

  defp add_fallback_request_id(opts, socket) do
    opts ++ [request_id: request_id(socket)]
  end

  defp add_status(response, status) do
    Map.put(response, :status, status)
  end
end
