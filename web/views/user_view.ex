defmodule RumblEc2.UserView do
  use RumblEc2.Web, :view
  alias RumblEc2.User

  def first_name(%User{name: name}) do
    name
    |> String.split(" ")
    |> Enum.at(0)
  end
end
