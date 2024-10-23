defmodule Simplificator3000Phoenix.Channel.ChannelConfig do
  alias Simplificator3000Phoenix.Channel

  @config_name :simplificator_3000_phoenix
  @config_section_name :channel
  @chanel_module_key :root_module
  @unauthorized_handler_key :unauthorized_handler
  @invalid_params_handler_key :invalid_params_handler

  def get_use_channel_module(options, caller_module) do
    with nil <- Keyword.get(options, @chanel_module_key),
         nil <- get_from_config(@chanel_module_key) do
      caller_module
      |> Module.split()
      |> Enum.take(1)
      |> Module.concat()
    end
  end

  def get_invalid_params_handler(options) do
    with nil <- Keyword.get(options, @invalid_params_handler_key, nil),
         nil <- get_from_config(@invalid_params_handler_key) do
      &Channel.DefaultHandlers.default_invalid_params_handler/2
    end
  end

  def get_unauthorized_handler(options) do
    with nil <- Keyword.get(options, @unauthorized_handler_key, nil),
         nil <- get_from_config(@unauthorized_handler_key) do
      &Channel.DefaultHandlers.default_unauthorized_handler/1
    end
  end

  def get_from_config(key) do
    Application.get_env(@config_name, @config_section_name)[key]
  end
end
