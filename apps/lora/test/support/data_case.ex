defmodule Lora.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Note: This application does not use a database, as per NFR-P-02.
  All state is held in GameServer and serialized into socket assigns.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Lora.DataCase
    end
  end

  setup _tags do
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  (No-op function since we don't use a database)
  """
  def setup_sandbox(_tags) do
    # No database setup needed
    :ok
  end
end
