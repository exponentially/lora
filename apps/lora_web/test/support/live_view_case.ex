defmodule LoraWeb.LiveViewCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's LiveView features.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import Phoenix.Component
      import LoraWeb.LiveViewCase

      # The default endpoint for testing
      @endpoint LoraWeb.Endpoint
    end
  end

  setup tags do
    test_session = LoraWeb.Test.setup_test_session(tags)
    %{conn: Phoenix.ConnTest.build_conn(), test_session: test_session}
  end
end
