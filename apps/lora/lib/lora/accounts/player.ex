defmodule Lora.Accounts.Player do
  @moduledoc """
  Schema for a player in the system.
  """

  @type t :: %__MODULE__{
          id: String.t(),
          sub: String.t(),
          name: String.t(),
          email: String.t(),
          inserted_at: DateTime.t()
        }

  @derive {Jason.Encoder, only: [:id, :name, :email]}
  defstruct [:id, :sub, :name, :email, :inserted_at]

  @doc """
  Create a player from Auth0 information.
  """
  def from_auth(%Ueberauth.Auth{} = auth) do
    %__MODULE__{
      id: auth.uid,
      sub: auth.uid,
      name: get_name_from_auth(auth),
      email: get_email_from_auth(auth),
      inserted_at: DateTime.utc_now()
    }
  end

  defp get_name_from_auth(%{info: %{name: name}}) when not is_nil(name), do: name
  defp get_name_from_auth(%{info: %{nickname: nickname}}) when not is_nil(nickname), do: nickname

  defp get_name_from_auth(%{info: %{first_name: first_name}}) when not is_nil(first_name),
    do: first_name

  defp get_name_from_auth(_), do: "Anonymous Player"

  defp get_email_from_auth(%{info: %{email: email}}) when not is_nil(email), do: email
  defp get_email_from_auth(_), do: nil
end
