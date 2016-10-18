defmodule RumblEc2.UserController do
  use RumblEc2.Web, :controller

  def index(conn, _params) do
    users = Repo.all(RumblEc2.User)
    render conn, "index.html", users: users
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get(RumblEc2.User, id)
    render conn, "show.html", user: user
  end
end
