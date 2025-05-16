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
      <div class={"relative #{@width} overflow-visible #{@player_position}"}>
        <div class={"card-fan size-#{@size} flex justify-center"} style="min-height: #{@fanHeight}px;">
          <%= for {{suit, rank}, index} <- Enum.with_index(@hand) do %>
            <div
              class={"card-stacked relative #{@card_height} #{@card_width} rounded-lg border-2 flex items-center justify-center #{LoraWeb.CardUtils.suit_color(suit)}"}
              style={"z-index: #{index + 10};"}>
              <div class={"card-value text-#{@value_size} #{LoraWeb.CardUtils.suit_color(suit)}"}>
                {LoraWeb.CardUtils.format_suit(suit)}
              </div>
              <span class={"card-corner top-left font-bold text-#{@corner_size} #{LoraWeb.CardUtils.suit_color(suit)}"}>
                <span class="card-rank">{LoraWeb.CardUtils.format_rank(rank)}</span>
                <br />
                <span class="card-suit">{LoraWeb.CardUtils.format_suit(suit)}</span>
              </span>
              <span class={"card-corner bottom-right font-bold text-#{@corner_size} #{LoraWeb.CardUtils.suit_color(suit)}"}>
                <span class="card-rank">{LoraWeb.CardUtils.format_rank(rank)}</span>
                <br />
                <span class="card-suit">{LoraWeb.CardUtils.format_suit(suit)}</span>
              </span>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp assign_stack_styles(assigns) do
    # Determine player position based on seat
    player_position = cond do
      assigns.player_seat == 0 -> "bottom-player"
      assigns.player_seat == 1 -> "left-player"
      assigns.player_seat == 2 -> "top-player"
      assigns.player_seat == 3 -> "right-player"
      true -> ""
    end

    assigns = assign(assigns, :player_position, player_position)

    case assigns.size do
      "small" ->
        assigns
        |> assign(:width, "w-full")  # Full width for better flexibility
        |> assign(:height, "h-36")
        |> assign(:card_width, "w-24")
        |> assign(:card_height, "h-36")
        |> assign(:text_size, "text-xl")
        |> assign(:corner_size, "base")  # Larger corner text for better visibility
        |> assign(:value_size, "xl")
        |> assign(:fanHeight, 180)

      "medium" ->
        assigns
        |> assign(:width, "w-full")  # Full width for better flexibility
        |> assign(:height, "h-44")
        |> assign(:card_width, "w-28")
        |> assign(:card_height, "h-44")
        |> assign(:text_size, "text-2xl")
        |> assign(:corner_size, "lg")  # Larger corner text for better visibility
        |> assign(:value_size, "2xl")
        |> assign(:fanHeight, 220)

      "large" ->
        assigns
        |> assign(:width, "w-full")  # Full width for better flexibility
        |> assign(:height, "h-52")
        |> assign(:card_width, "w-32")
        |> assign(:card_height, "h-52")
        |> assign(:text_size, "text-3xl")
        |> assign(:corner_size, "xl")  # Larger corner text for better visibility
        |> assign(:value_size, "3xl")
        |> assign(:fanHeight, 260)
    end
  end
end
