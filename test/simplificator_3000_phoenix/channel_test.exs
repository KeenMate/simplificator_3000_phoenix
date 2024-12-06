defmodule Simplificator3000Phoenix.ChannelTest do
  use ExUnit.Case

  # doctest Simplificator3000Phoenix

  setup_all do
    [
      test_web_module: MyTestWeb,
      join_fn_ast: quote do
        def join(_, _, socket) do
          {:ok, socket}
        end
      end
    ]
  end

  describe "Channel macro" do
    test "message/3 compiles", ctx do
      channel_module = Module.concat(ctx.test_web_module, MyChannelWithMessage)

      compiled_output =
        quote do
          defmodule unquote(channel_module) do
            use Simplificator3000Phoenix.Channel

            unquote(ctx.join_fn_ast)

            message my_message(payload, socket) do
              {:ok, 1}
            end
          end
        end
        |> Code.compile_quoted()

      assert match?([{^channel_module, _}], compiled_output)
    end

    test "msg/3 compiles", ctx do
      channel_module = Module.concat(ctx.test_web_module, MyChannelWithMsg)

      compiled_output =
        quote do
          defmodule unquote(channel_module) do
            use Simplificator3000Phoenix.Channel

            unquote(ctx.join_fn_ast)

            msg my_message(payload, socket) do
              {:ok, 1}
            end
          end
        end
        # |> tap(&IO.puts("Generated msg/3: \n\n#{Macro.to_string(&1)}"))
        |> Code.compile_quoted()

      assert match?([{^channel_module, _}], compiled_output)
    end

    test "sub/2 compiles", ctx do
      channel_module = Module.concat(ctx.test_web_module, MyChannelWithSub)

      compiled_output =
        quote do
          defmodule unquote(channel_module) do
            use Simplificator3000Phoenix.Channel

            unquote(ctx.join_fn_ast)

            sub event(param1, param2, socket) do
              {:noreply, socket}
            end
          end
        end
        # |> tap(&IO.puts("Generated sub/2: \n\n#{Macro.to_string(&1)}"))
        |> Code.compile_quoted()

      assert match?([{^channel_module, _}], compiled_output)
    end
  end
end
