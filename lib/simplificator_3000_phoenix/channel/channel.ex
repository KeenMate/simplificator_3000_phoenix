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

  defmacro payload(payload) do
    Module.put_attribute(__CALLER__.module, :payload, payload)
  end

  defmacro defmsg(event, payload_template, opts) do
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

  defmacro defmsg({event, _, params}, [do: block]) do
    payload_template =
      __CALLER__.module
      |> Module.get_attribute(:payload, %{})
      |> Macro.escape()
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
            [unquote_splicing([payload, socket])] = [payload, socket]

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
    |> IO.inspect(label: "defmsg result")
  end

  defmacro sub(name, options \\ []) do
    handler_name = Keyword.get(options, :handler, name)

    quote do
      @impl true
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
