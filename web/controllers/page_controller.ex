defmodule RumblEc2.PageController do
  use RumblEc2.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
