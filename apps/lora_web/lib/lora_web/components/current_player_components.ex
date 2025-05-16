defmodule LoraWeb.CurrentPlayerComponents do
  use Phoenix.Component
  import LoraWeb.CardUtils

  attr :player, :map, required: true
  attr :game, :map, required: true
  attr :legal_moves, :list, required: true
  attr :current_contract, :atom, required: true

  def player_hand(assigns) do
    assigns = assign(assigns, :hand, Map.get(assigns.game.hands, assigns.player.seat, []))

    ~H"""
    <div class={
      if assigns.game.current_player == assigns.player.seat,
        do:
          "bg-gray-900/80 backdrop-blur-md rounded-xl p-5 shadow-2xl border border-gray-700",
        else: "bg-gray-900/80 backdrop-blur-md rounded-xl p-5 shadow-2xl border border-gray-700"
    }>
      <!-- Player info -->
      <div class="flex justify-between items-center mb-5">
        <div class="flex items-center gap-3">
          <div>
            <span class="font-bold text-xl text-white">{@player.name}</span>
            <div class="flex items-center gap-2 mt-1">
              <span class="text-sm text-gray-300">(Seat {String.trim("#{@player.seat}")})</span>
              <%= if @game.dealer_seat == @player.seat do %>
                <span class="inline-flex items-center rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-700 border border-blue-200">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-3 w-3 mr-1"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  Dealer
                </span>
              <% end %>
            </div>
          </div>
        </div>

        <div class="flex items-center gap-4">
          <%= if @game.phase == :playing && @game.current_player == @player.seat do %>
            <span class="inline-flex items-center px-4 py-1.5 rounded-full text-sm font-semibold bg-gradient-to-r from-green-600 to-green-500 text-white shadow-md">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"
                />
              </svg>
              Your Turn
            </span>
          <% end %>

          <div class="bg-gray-800 px-3 py-2 rounded-lg border border-gray-700">
            <span class="text-xl font-bold text-white">
              {Map.get(@game.scores, @player.seat, 0)}
            </span>
          </div>
        </div>
      </div>

    <!-- Player hand - emphasized -->
      <h3 class="text-lg font-semibold text-center mb-4 text-gray-700">Your Hand</h3>
      <div class="overflow-x-auto pb-4">
        <div class="flex gap-3 justify-center min-w-max">
          <%= for {suit, rank} <- @hand do %>
            <button
              phx-click="play_card"
              phx-value-suit={suit}
              phx-value-rank={rank}
              class={"card relative flex items-center justify-center h-32 w-20 rounded-lg shadow-lg transition-all duration-200 ease-in-out hover:-translate-y-3 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 " <>
                      suit_color(suit) <>
                      (if Enum.member?(@legal_moves, {suit, rank}),
                        do: " bg-white hover:bg-gray-50 cursor-pointer border border-gray-200",
                        else: " bg-gray-300 cursor-not-allowed opacity-50")}
              disabled={not Enum.member?(@legal_moves, {suit, rank})}
            >
              <span class="text-3xl font-bold">{format_rank(rank)}</span>
              <span class="absolute top-1 left-1 text-lg">
                {format_suit(suit)}
              </span>
              <span class="absolute bottom-1 right-1 text-lg transform rotate-180">
                {format_suit(suit)}
              </span>
            </button>
          <% end %>
        </div>
      </div>

      <%= if @current_contract == :lora && @game.current_player == @player.seat && Enum.empty?(@legal_moves) && length(@hand) > 0 do %>
        <div class="mt-6 text-center">
          <button
            phx-click="pass"
            class="bg-gradient-to-r from-amber-500 to-amber-600 text-white py-2.5 px-5 rounded-lg hover:from-amber-600 hover:to-amber-700 shadow-md text-sm font-semibold transition-all"
          >
            Pass Turn
          </button>
        </div>
      <% end %>
    </div>
    """
  end
end
