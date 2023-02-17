defmodule Simplificator3000Phoenix.Channel do
  require Logger
  alias Simplificator3000Phoenix.Channel.ChannelConfig, as: Config

  defmacro __using__(options) do
    use_channel_module = Config.get_use_channel_module(options, __CALLER__.module)
    unauthorize_handler = Config.get_unauthorized_handler(options)

    quote do
      use unquote(use_channel_module), :channel

      require Logger

      import Simplificator3000Phoenix.Channel.ChannelHelpers
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :payload, [])

      @impl true
      def handle_in(event, payload, socket) do
        socket = put_request_id(socket)

        event_atom = String.to_existing_atom(event)
        if function_exported?(__MODULE__, event_atom, 2) do
          apply(__MODULE__, event_atom, [payload, socket])
        else
          Logger.warn("No handler for event #{event} in #{__MODULE__}")
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

      This way you can create event handler by yourself thus allowing you to make use of mupltiple function pattern matching.
  """
  defmacro message(event, payload_template, opts) do
    handler_name = String.to_atom(Atom.to_string(event) <> "_handler")

    quote do
      def unquote(handler_name)(payload, socket) do
        if Simplificator3000Phoenix.PermissionsCheck.check_permissions(socket, unquote(Macro.escape(opts))) do
          # Parse and validate params
          with payload <- Simplificator3000.MapHelpers.snake_cased_map_keys(payload),
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

  defmacro message({event, _, params}, [do: block]) do
    payload_template = Module.get_attribute(__CALLER__.module, :payload) || quote do: %{}
    Module.delete_attribute(__CALLER__.module, :payload)

    [payload, socket, opts] =
      case params do
          [payload, socket, opts] ->
              [payload, socket, opts]

          [payload, socket] ->
              [payload, socket, []]
      end

    quote do
      def unquote(event)(payload, socket) do
        if Simplificator3000Phoenix.PermissionsCheck.check_permissions(socket, unquote(Macro.escape(opts))) do
          # Parse and validate params
          with payload <- Simplificator3000.MapHelpers.snake_cased_map_keys(payload),
               {:ok, parsed_payload} <- Tarams.cast(payload, unquote(payload_template)) do
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

  defmacro sub(name, options \\ []) do
    handler_name = Keyword.get(options, :handler, name)

    quote do
      def handle_info({unquote(name), data}, socket) do
        case apply(__MODULE__, unquote(handler_name), [socket, data]) do
          {:stop, _, _} = val ->
            val

          {:noreply, socket} ->
            {:noreply, socket}

          _ ->
            {:noreply, socket}
        end
      end
    end
  end

  defmacro no_reply do
    quote do
      {:noreply, var!(socket)}
    end
  end
end
