defmodule LoraWeb.PlayerComponents do
  use Phoenix.Component
  import LoraWeb.GameUtils
  import LoraWeb.DeckCompoents
  import LoraWeb.CoreComponents
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
            <%= if @current_player do %>
              <.icon name="hero-bookmark-solid" class="text-yellow-500" />
            <% end %>
            <%= unless @is_online do %>
              <span class="loading loading-ball loading-sm bg-red-500"></span>
            <% end %>
            <span class="line-clamp-1" title={@player_name}>{@player_name}</span>
          </span>
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
      |> assign(:debug, Mix.env() == :dev)

    ~H"""
    <%= if assigns.game.phase == :playing do %>
      <div class={"relative #{@width} overflow-visible"}>
        <div class={"card-fan size-#{@size} flex justify-center"} style="min-height: #{@fanHeight}px;">
          <%= for {{suit, rank}, index} <- Enum.with_index(@hand) do %>
            <%= if @debug do %>
              <.card_front suit={suit} rank={rank} class={"z-#{index}"} />
            <% else %>
              <.card_back class={"z-#{index}"} />
            <% end %>
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
        |> assign(:width, "w-full")
        |> assign(:height, "h-36")
        |> assign(:fanHeight, 180)

      "large" ->
        assigns
        |> assign(:width, "w-full")
        |> assign(:height, "h-52")
        |> assign(:fanHeight, 260)

      _medium ->
        assigns
        |> assign(:width, "w-full")
        |> assign(:height, "h-44")
        |> assign(:fanHeight, 220)
    end
  end
end
