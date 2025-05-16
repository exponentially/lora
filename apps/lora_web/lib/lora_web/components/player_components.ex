defmodule LoraWeb.PlayerComponents do
  use Phoenix.Component
  import LoraWeb.GameUtils

  attr :player, :map, required: true
  attr :game, :map, required: true
  attr :presences, :map, required: true
  attr :player_seat, :integer, required: true
  attr :is_current_player, :boolean, default: false
  # "small", "medium", or "large"
  attr :size, :string, default: "medium"

  def player_plate(assigns) do
    # Check if this seat is the current user's seat (the person viewing the game)
    is_current_user = assigns.player && assigns.player.seat == assigns.player_seat

    # Only show opponent plates (not the current user, as they're shown at the bottom)
    player =
      if is_current_user do
        # Return nil if this is the current user's seat
        nil
      else
        # Otherwise find the player for this seat
        Enum.find(assigns.game.players, &(&1.seat == assigns.player_seat))
      end

    assigns =
      assigns
      |> assign(:player_name, find_player_name(assigns.game, assigns.player_seat))
      # Use seated_player to avoid conflicts with assigns.player
      |> assign(:seated_player, player)
      |> assign(:is_online, player && Map.has_key?(assigns.presences, player && player.id))
      |> assign(:current_player, assigns.game.current_player == assigns.player_seat)
      |> assign(:score, Map.get(assigns.game.scores, assigns.player_seat, 0))
      |> assign(:is_current_user, is_current_user)

    # Determine classes based on size
    assigns =
      assign(
        assigns,
        :outer_class,
        case assigns.size do
          "small" ->
            "bg-gray-900/80 rounded-lg px-4 py-2 mb-4 shadow-xl backdrop-blur-md border border-gray-700/50 w-full"

          "medium" ->
            "bg-gray-900/80 rounded-lg px-5 py-2 mb-4 shadow-xl backdrop-blur-md border border-gray-700/50 w-80"

          "large" ->
            "bg-gray-900/80 rounded-lg px-5 py-3 mb-4 shadow-xl backdrop-blur-md border border-gray-700/50 w-full"
        end
      )

    assigns =
      assign(
        assigns,
        :name_class,
        case assigns.size do
          "small" -> "text-base font-bold text-white"
          "medium" -> "text-lg font-bold text-white"
          "large" -> "text-xl font-bold text-white"
        end
      )

    assigns =
      assign(
        assigns,
        :score_box_class,
        case assigns.size do
          "small" -> "bg-gray-800 px-2 py-1.5 rounded-lg border border-gray-700"
          "medium" -> "bg-gray-800 px-3 py-2 rounded-lg border border-gray-700"
          "large" -> "bg-gray-800 px-4 py-2.5 rounded-lg border border-gray-700"
        end
      )

    assigns =
      assign(
        assigns,
        :score_text_class,
        case assigns.size do
          "small" -> "text-base font-bold text-white"
          "medium" -> "text-xl font-bold text-white"
          "large" -> "text-2xl font-bold text-white"
        end
      )

    assigns =
      assign(
        assigns,
        :status_size,
        case assigns.size do
          "small" -> "w-2.5 h-2.5"
          "medium" -> "w-3 h-3"
          "large" -> "w-3.5 h-3.5"
        end
      )

    ~H"""
    <div class={@outer_class}>
      <div class="flex items-center justify-between">
        <div>
          <span class={@name_class <> " flex items-center gap-2"}>
            {@player_name}
            <%= if @is_online do %>
              <span class={"inline-block #{@status_size} bg-green-500 rounded-full"} title="Online">
              </span>
            <% else %>
              <span class={"inline-block #{@status_size} bg-red-500 rounded-full"} title="Offline">
              </span>
            <% end %>
          </span>
          <%= if @current_player do %>
            <span class="inline-flex items-center gap-1 mt-1 text-sm font-medium text-green-600">
              <svg
                class="h-4 w-4"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  fill-rule="evenodd"
                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                  clip-rule="evenodd"
                />
              </svg>
              Current turn
            </span>
          <% end %>
        </div>
        <div class={@score_box_class}>
          <span class={@score_text_class}>{@score}</span>
        </div>
      </div>
    </div>
    """
  end

  attr :player_seat, :integer, required: true
  attr :game, :map, required: true
  # "small", "medium", or "large"
  attr :size, :string, default: "medium"

  def card_stack(assigns) do
    assigns =
      assigns
      |> assign(:hand, Map.get(assigns.game.hands, assigns.player_seat, []))
      |> assign(:hand_size, length(Map.get(assigns.game.hands, assigns.player_seat, [])))
      |> assign_stack_styles()

    ~H"""
    <%= if assigns.game.phase == :playing do %>
      <div class={"relative #{@width} overflow-x-auto"}>
        <div class="flex">
          <%= for {{suit, rank}, index} <- Enum.with_index(@hand) do %>
            <div
              class={"card-stacked relative #{@card_height} #{@card_width} bg-white rounded-lg shadow-xl border border-gray-200 flex items-center justify-center #{LoraWeb.CardUtils.suit_color(suit)}"}
              style={"margin-left: #{if index == 0, do: "0px", else: "-55px"}; z-index: #{index}"}>
              <span class="text-lg font-bold">{LoraWeb.CardUtils.format_rank(rank)}{LoraWeb.CardUtils.format_suit(suit)}</span>
              <span class="absolute top-1 left-1 text-sm">
                {LoraWeb.CardUtils.format_rank(rank)}{LoraWeb.CardUtils.format_suit(suit)}
              </span>
              <span class="absolute bottom-1 right-1 text-sm transform rotate-180">
                {LoraWeb.CardUtils.format_rank(rank)}{LoraWeb.CardUtils.format_suit(suit)}
              </span>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp assign_stack_styles(assigns) do
    case assigns.size do
      "small" ->
        assigns
        |> assign(:width, "w-24")
        |> assign(:height, "h-24")
        |> assign(:card_width, "w-16")
        |> assign(:card_height, "h-24")
        |> assign(:text_size, "text-lg")
        |> assign(:spacing, "left-3")

      "medium" ->
        assigns
        |> assign(:width, "w-32")
        |> assign(:height, "h-28")
        |> assign(:card_width, "w-20")
        |> assign(:card_height, "h-28")
        |> assign(:text_size, "text-2xl")
        |> assign(:spacing, "left-6")

      "large" ->
        assigns
        |> assign(:width, "w-36")
        |> assign(:height, "h-32")
        |> assign(:card_width, "w-24")
        |> assign(:card_height, "h-32")
        |> assign(:text_size, "text-3xl")
        |> assign(:spacing, "left-8")
    end
  end
end
