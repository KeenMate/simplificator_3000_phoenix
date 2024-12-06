defmodule Simplificator3000Phoenix.Channel do
  alias Simplificator3000Phoenix.Internal.MacroHelpers
  alias Simplificator3000Phoenix.Channel.ChannelConfig, as: Config
  alias Simplificator3000.Result.{Ok, Error}

  require Logger

  defmacro __using__(options) do
    use_channel_module = Config.get_use_channel_module(options, __CALLER__.module)
    unauthorize_handler = Config.get_unauthorized_handler(options)

    quote do
      use unquote(use_channel_module), :channel

      require Logger

      import Simplificator3000Phoenix.Channel.ChannelHelpers
      import Simplificator3000Phoenix.Conn
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :payload, [])

      @impl true
      def handle_in(event, payload, socket) do
        socket = put_request_id(socket)

        event_atom = String.to_existing_atom(event)

        if function_exported?(__MODULE__, event_atom, 2) do
          apply(__MODULE__, event_atom, [payload, socket])
        else
          Logger.warning("No handler for event #{event} in #{__MODULE__}")
          {:noreply, socket}
        end
      end

      def authorized?(topic, payload, socket) do
        Simplificator3000Phoenix.PermissionsCheck.check_permissions(
          socket,
          unquote(Macro.escape(options))
        )
      end

      def unauthorized(socket) do
        unquote(unauthorize_handler).(socket)
      end

      # TODO: Think about how handle_info should be wrapped (for request_id)
    end
  end

  @doc """
  Defines a payload schema for first following message handler (that consumes the schema and prevents further use of this schema).
  Payload schema is a map with keys and types.
  For schema documentation see [`Tarams`](https://hexdocs.pm/tarams/readme.html) library.
  """
  defmacro payload(payload) do
    Module.put_attribute(__CALLER__.module, :payload, payload)
  end

  @doc """
  Defines a message handler.
  Permissions can be passed via `opts` param to validate request's rights.
  Event handler receives parsed and validated payload.

  ## Options
      - `:unauthorized_handler` - function to be called when user is not authorized to perform the action.
      - `:invalid_params_handler` - function to be called when params are invalid.
      - `:permissions` - list of permissions to check.

  ## Examples
      1. As a function definition:
      ```
      message event_name(payload, socket) do
        # Code
      end
      ```
      2. As a function declaration:
      ```
      message(
        :event_name,
        payload_template,
        opts
      )

      def event_name(payload, socket) do
        # Code
      end
      ```

      This way you can create event handler by yourself thus allowing you to make use of multiple function pattern matching.
  """
  defmacro message(event, payload_template, opts) do
    handler_name = String.to_atom(Atom.to_string(event) <> "_handler")

    quote do
      def unquote(handler_name)(payload, socket) do
        if Simplificator3000Phoenix.PermissionsCheck.check_permissions(
             socket,
             unquote(Macro.escape(opts))
           ) do
          # Parse and validate params
          with payload <- Simplificator3000Phoenix.Conn.parse_payload(payload),
               {:ok, parsed_payload} <- Tarams.cast(payload, unquote(payload_template)) do
            # Call user code
            apply(__MODULE__, unquote(event), [parsed_payload, socket])
          else
            {:error, errors} ->
              # Handle invalid params
              unquote(Config.get_invalid_params_handler(opts)).(socket, errors)
          end
        else
          # Handle unauthorized
          unquote(Config.get_unauthorized_handler(opts)).(socket)
        end
      end
    end
  end

  defmacro message({event, _, params}, do: block) do
    payload_template = Module.get_attribute(__CALLER__.module, :payload) || quote do: %{}
    Module.delete_attribute(__CALLER__.module, :payload)

    # used in order to reference to the same name as the author chose (e.g. for "socket") (AST stuff)
    [payload, socket, opts] =
      case params do
        [payload, socket, opts] ->
          [payload, socket, opts]

        [payload, socket] ->
          [payload, socket, []]
      end

    quote do
      def unquote(event)(payload, socket) do
        if Simplificator3000Phoenix.PermissionsCheck.check_permissions(
             socket,
             unquote(Macro.escape(opts))
           ) do
          # Parse and validate params
          with payload <- Simplificator3000Phoenix.Conn.parse_payload(payload),
               {cid, payload} <- maybe_extract_payload_cid(payload),
               {:ok, parsed_payload} <- Tarams.cast(payload, unquote(payload_template)) do
            # will either set it (not null) or remove (if null)
            Logger.metadata(cid: cid)

            # Unwrap payload
            [unquote_splicing([payload, socket])] = [parsed_payload, socket]

            # Call user code
            unquote(block)
          else
            {:error, errors} ->
              # Handle invalid params
              unquote(Config.get_invalid_params_handler(opts)).(socket, errors)
          end
        else
          # Handle unauthorized
          unquote(Config.get_unauthorized_handler(opts)).(socket)
        end
      end
    end
  end

  @doc """
  A more rich version of the "barebone" `message` macro. The difference is that this helper manages to execute your code in a separate linked `Task`, prepares ctx
  and then automatically sends given response with the metadata and request_id set up.
  Data and metadata are also mapped to the serializable versions (using `map_response`).

  No longer shall we forget do these extra steps a-ha :).

  ## Extra variables available
    * `ctx` - just the result of `user_ctx(socket)` call (should contain `%UserContext{}` struct with information about current user)
    * `channel_pid` - this is the PID of the channel (in case you want to send custom message to this channel)
  """
  defmacro msg({event, _, params}, do: block) do
    # used in order to reference to the same name as the author chose for "socket" (AST stuff)
    [payload, socket, opts] =
      case params do
        [payload, socket, opts] ->
          [payload, socket, opts]

        [payload, socket] ->
          [payload, socket, []]
      end

    channel_pid_var =
      # to get rid of the warning about unused `channel_pid`
      if MacroHelpers.var_referenced?(block, :channel_pid) do
        quote do: (var!(channel_pid) = self())
      end

    quote do
      message unquote(event)(var!(payload), var!(socket), unquote(opts)) do
        ref = socket_ref(var!(socket))
        var!(ctx) = user_ctx(var!(socket))
        unquote(channel_pid_var)

        [unquote_splicing([payload, socket])] = [var!(payload), var!(socket)]

        Task.start_link(fn ->
          try do
            result = unquote(block)

            case result do
              ## Oks

              {:ok, data} ->
                success_reply(ref, map_response(data), request_id: var!(ctx).request_id)

              {:ok, data, metadata} ->
                success_reply(ref, map_response(data), metadata: map_response(metadata), request_id: var!(ctx).request_id)

              %Ok{data: data, metadata: metadata} ->
                success_reply(ref, map_response(data), metadata: map_response(metadata), request_id: var!(ctx).request_id)

              ## Errors

              {:error, reason} ->
                error_reply(ref, reason: if(is_atom(reason), do: reason), request_id: var!(ctx).request_id)

              {:error, reason, metadata} ->
                error_reply(ref, reason: if(is_atom(reason), do: reason), metadata: map_response(metadata), request_id: var!(ctx).request_id)

              %Error{reason: reason, metadata: metadata} ->
                error_reply(ref, reason: if(is_atom(reason), do: reason), metadata: map_response(metadata), request_id: var!(ctx).request_id)
            end
          rescue error ->
            Logger.error("Error occurred while processing message #{to_string unquote(event)}", reason: inspect(error))

            error_reply(ref, reason: :runtime_error, request_id: var!(ctx).request_id)
          end
        end)

        no_reply()
      end
    end
    # |> tap(&IO.puts("message/3 output: \n\n#{Macro.to_string(&1)}"))
  end

  @doc """
  Creates a `handle_info` definition which simplifies the syntax required for this code.
  From this:
  ```
  def handle_info({:event, param1, param2, ...}, socket) do
    ...code
    {:noreply, socket}
  end
  ```

  To this:
  ```
  sub event(param1, param2, ..., socket) do
    ...code
    {:noreply, socket}
  end
  ```
  """
  defmacro sub(name, options \\ [])

  defmacro sub({event, _, params}, do: block) do
    # provide `@impl true` tag for to-be generated `handle_info/3` GenServer callback
    impl_tag =
      if not Module.get_attribute(__CALLER__.module, :simplificator_3000_phoenix_handle_info_impl_set, false) do
        Module.put_attribute(__CALLER__.module, :simplificator_3000_phoenix_handle_info_impl_set, true)
        quote do
          @impl true
        end
      end

    quote do
      unquote(impl_tag)
      def handle_info({unquote(event), unquote_splicing(params)}, socket) do
        unquote(block)
      end
    end
  end

  defmacro sub(name, options) do
    handler_name = Keyword.get(options, :handler, name)

    quote do
      def handle_info({unquote(name), data}, socket) do
        case apply(__MODULE__, unquote(handler_name), [socket, data]) do
          {:stop, _, _} = val ->
            val

          {:noreply, socket} ->
            no_reply()

          _ ->
            no_reply()
        end
      end
    end
  end

  defmacro no_reply do
    quote do
      {:noreply, var!(socket)}
    end
  end

  @spec maybe_extract_payload_cid(map() | list()) :: {binary() | nil, map() | list()}
  def maybe_extract_payload_cid(%{} = payload) do
    {with_cid, rest_payload} = Map.split(payload, ["cid"])

    {with_cid["cid"], rest_payload}
  end

  def maybe_extract_payload_cid(payload) when is_list(payload) do
    {nil, payload}
  end
end
