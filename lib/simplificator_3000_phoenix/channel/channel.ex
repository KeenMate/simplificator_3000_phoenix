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

      @impl true
      def handle_in(event, payload, socket) do
        socket = put_request_id(socket)

        apply(__MODULE__, :handle_message, [event, payload, socket])
        # |> IO.inspect(label: "#{__MODULE__}.#{event} return")
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

  defmacro message(event, payload_template \\ %{}, options \\ []) do
    invalid_params_handler = Config.get_invalid_params_handler(options)
    unauthorize_handler = Config.get_unauthorized_handler(options)

    #
    escaped_template =
      case payload_template do
        %{} -> Macro.escape(payload_template)
        _ -> payload_template
      end

    quote do
      def handle_message(unquote(Atom.to_string(event)), raw_payload, socket) do
        # check permissions

        if Simplificator3000Phoenix.PermissionsCheck.check_permissions(
             socket,
             unquote(Macro.escape(options))
           ) do
          # parse and validate params
          with payload <- Simplificator3000.MapHelpers.snake_cased_map_keys(raw_payload),
               {:ok, parsed_payload} <-
                 Tarams.cast(payload, unquote(escaped_template)) do
            # * call handler function
            apply(__MODULE__, unquote(event), [socket, parsed_payload])
          else
            {:error, errors} ->
              # handle invalid params
              unquote(invalid_params_handler).(socket, errors)
          end
        else
          # handle unauthorized
          unquote(unauthorize_handler).(socket)
        end
      end
    end
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