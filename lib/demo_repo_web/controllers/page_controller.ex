defmodule DemoRepoWeb.PageController do
  use DemoRepoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
