defmodule RumblEc2.UserController do
  use RumblEc2.Web, :controller

  def index(conn, _params) do
    users = Repo.all(RumblEc2.User)
    render conn, "index.html", users: users
  end
end
