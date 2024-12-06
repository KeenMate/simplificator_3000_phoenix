ExUnit.start()

defmodule MyTestWeb do
  @moduledoc """
  Mock Web module used to imitate real web module in real web application in real life scenario (really)
  """

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def channel do
    quote do
      use Phoenix.Channel, log_join: :debug, log_handle_in: :debug

      import Simplificator3000Phoenix.Channel.ChannelHelpers
      import Simplificator3000Phoenix.Conn
    end
  end
end
