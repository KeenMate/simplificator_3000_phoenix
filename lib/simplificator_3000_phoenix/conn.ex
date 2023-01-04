defmodule Simplificator3000Phoenix.Conn do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]
  import Simplificator3000.MapHelpers, only: [camel_cased_map_keys: 1]

  def success(data \\ nil, metadata \\ nil) do
    %{data: data, metadata: metadata}
  end

  def success_response(conn, data \\ nil, metadata \\ nil) do
    response = success(data, metadata) |> camel_cased_map_keys()

    conn
    |> put_status(200)
    |> json(response)
  end

  def error(opts \\ []) do
    %{
      error: %{
        code: Keyword.get(opts, :reason),
        msg: Keyword.get(opts, :msg),
        detail: Keyword.get(opts, :detail)
      },
      metadata: Keyword.get(opts, :metadata)
    }
  end

  def error_response(conn, opts \\ []) do
    response = error(opts) |> camel_cased_map_keys()

    conn
    |> put_status(Keyword.get(opts, :response_code, 500))
    |> json(response)
  end
end
