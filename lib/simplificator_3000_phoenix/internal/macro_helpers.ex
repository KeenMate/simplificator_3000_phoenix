defmodule Simplificator3000Phoenix.Internal.MacroHelpers do
  @doc """
  Walks through given AST and tries to find whether given `variable` is used or not
  """
  def var_referenced?(ast, variable) do
    ast
    |> Macro.postwalker()
    |> Enum.reduce_while(false, fn
      {^variable, _, _}, false ->
        {:halt, true}

      _, false ->
        {:cont, false}
    end)
  end
end
