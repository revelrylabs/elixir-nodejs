defmodule ServerSideRender do
  use Retry

  @moduledoc """
  This plug takes HTML requests, forwards them to our controllers as JSON
  requests, takes the resulting JSON and POSTs it to a rendering service,
  then transforms the response back into HTML using the output from the
  rendering service.

  usage:

  ```elixir
  plug ServerSideRender
  ```
  """

  # Base URL of render service goes here.
  def init(options) do
    options
  end

  # Apply to HTML requests only.
  def should_apply?(conn) do
    accept_header = List.first(Plug.Conn.get_req_header(conn, "accept")) || ""
    String.contains?(accept_header, "text/html")
  end

  # Change the HTML request so it will be processed first as JSON.
  def change_format_to_json(conn) do
    Plug.Conn.put_private(conn, :phoenix_format, "json")
  end

  # Register the response transformation handler that will call the service.
  def register_before_send(conn, url) do
    hook = fn conn ->
      before_send(conn, url)
    end

    Plug.Conn.register_before_send(conn, hook)
  end

  # Success. Replace the body and set the correct content type.
  def handle_service_response(conn, {:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    %{conn | resp_body: body} |> Plug.Conn.put_resp_header("Content-Type", "text/html")
  end

  # The service didn't have a view for us.
  def handle_service_response(_conn, {:ok, %HTTPoison.Response{status_code: 404}}) do
    raise "Not Found."
  end

  # The service sent an unexpected or error code.
  def handle_service_response(conn, {:ok, _}) do
    conn
  end

  # Something bad happened.
  def handle_service_response(_conn, {:error, error}) do
    {:error, error}
  end

  # The response transformation.
  def before_send(conn, url) do
    body = to_string(conn.resp_body)
    headers = [{"Content-Type", "application/json"}]

    retry with: exp_backoff() |> randomize |> expiry(10_000) do
      service_response = HTTPoison.post(url, body, headers)
      handle_service_response(conn, service_response)
    end
  end

  # Plug API
  def call(conn) do
    url = ServerSideRender.Server.get_url()

    if should_apply?(conn) do
      conn
      |> change_format_to_json()
      |> register_before_send(url)
    else
      conn
    end
  end
end
