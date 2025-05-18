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
    <div
      class={"border-dashed border-4 rounded-lg p-1 " <> @class}
      style="border-color: rgba(255,241,75, 0.5); width: 8rem; height: 11rem;"
    >
      <%= if @trick_card do %>
        <% {_, {suit, rank}} = @trick_card %>
        <LoraWeb.DeckCompoents.card_front
          suit={suit}
          rank={rank}
          class={"shadow-md #{if is_winning_card?(@game, @seat), do: "winner-card", else: ""}"}
          id={"trick-card-#{@seat}-#{suit}-#{rank}"}
        />
      <% end %>
    </div>
    """
  end

  attr :game, :map, required: true
  attr :player, :map, required: true
  attr :current_contract, :atom, required: true

  def current_trick(assigns) do
    ~H"""
    <div
      class="bg-green-900/1 rounded-full backdrop-blur-md shadow-[0_50px_60px_-15px_rgba(0,0,0,0.3)] p-4 size-[520px]"
      style="transform: rotate3d(-1,0.5,0.5,60deg);"
    >
      <%= if @current_contract == :lora do %>
        <div class="text-white text-center font-semibold mb-3">Lora Layout</div>
        <div class="grid grid-cols-1 gap-3">
          <%= for suit <- [:clubs, :diamonds, :hearts, :spades] do %>
            <div class="flex items-center">
              <div class="w-6 text-white text-xl">{LoraWeb.CardUtils.format_suit(suit)}</div>
              <div class="flex flex-grow overflow-x-auto">
                <%= for {card_suit, rank} <- @game.lora_layout[suit] || [] do %>
                  <div class={"card-mini flex items-center justify-center h-10 w-8 bg-white rounded-md mr-1 shadow-md #{LoraWeb.CardUtils.suit_color(card_suit)}"}>
                    {LoraWeb.CardUtils.format_rank(rank)}
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% else %>
        <div class="relative h-full py-4 flex items-center justify-center">
          <div class="text-center font-semibold mb-3 text-3xl text-yellow-300">
            {Lora.Contract.name(@current_contract)}
          </div>
          <% opponent_seats = LoraWeb.GameUtils.calculate_opponent_seats(@player.seat) %>
          <%= for {seat, class} <- [
            {@player.seat, "absolute transform -translate-x-1/2 bottom-4 left-1/2"},
            {opponent_seats.top, "absolute transform -translate-x-1/2 top-4 left-1/2"},
            {opponent_seats.left, "absolute transform -translate-y-1/2 top-1/2 left-4"},
            {opponent_seats.right, "absolute transform -translate-y-1/2 top-1/2 right-4"}
          ] do %>
            <.current_trick_card class={class} seat={seat} game={@game} />
          <% end %>
        </div>
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
