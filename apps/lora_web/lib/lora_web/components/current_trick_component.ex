defmodule LoraWeb.CurrentTrickComponent do
  use Phoenix.Component
  use Gettext, backend: LoraWeb.Gettext
  use LoraWeb, :verified_routes

  attr :game, :map, required: true
  attr :seat, :integer, required: true
  attr :class, :string, default: ""

  def current_trick_card(assigns) do
    # Helper function to determine if a card is the winner
    assigns =
      assigns
      |> assign(trick_card: Enum.find(assigns.game.trick, fn {s, _} -> s == assigns.seat end))

    ~H"""
    <div class={@class}>
      <%= if @trick_card do %>
        <% {_, {suit, rank}} = @trick_card %>
        <LoraWeb.DeckCompoents.card_front
          suit={suit}
          rank={rank}
          class={"animate-in card-throw-right #{if is_winning_card?(@game, @seat), do: "winner-card", else: ""}"}
          id={"trick-card-#{@seat}-#{suit}-#{rank}"}
        />
      <% end %>
    </div>
    """
  end

  defp is_winning_card?(game, seat) do
    # Determine if we have a complete trick (4 cards)
    trick_complete = length(game.trick) == 4
    # Calculate the winner if trick is complete
    winner_seat =
      if trick_complete,
        do: Lora.Deck.trick_winner(game.trick),
        else: nil

    trick_complete && seat == winner_seat
  end
end
