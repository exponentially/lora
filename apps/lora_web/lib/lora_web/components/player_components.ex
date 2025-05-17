defmodule LoraWeb.PlayerComponents do
  use Phoenix.Component
  import LoraWeb.GameUtils
  import LoraWeb.DeckCompoents
  import LoraWeb.CoreComponents

  @type card_stack_assigns :: %{
          player_seat: non_neg_integer(),
          game: map(),
          size: :small | :medium | :large
        }

  @doc """
  Renders a player's info plate in a card game UI. Shows player name, online status,
  score, and indicates if they're the current player. Adapts to different sizes.

  The plate is only displayed for opponents; the current user's info is shown elsewhere.
  """
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
          "small" -> "px-4 py-2 w-full"
          "medium" -> "px-5 py-2 w-80"
          "large" -> "px-5 py-3 w-full"
        end
      )

    assigns =
      case assigns.size do
        "small" ->
          assign(
            assigns,
            name_class: "text-base",
            score_box_class: "px-2 py-1.5",
            score_text_class: "text-base",
            status_size: "w-2.5 h-2.5"
          )

        "medium" ->
          assign(
            assigns,
            name_class: "text-lg",
            score_box_class: "px-3 py-2",
            score_text_class: "text-xl",
            status_size: "w-3 h-3"
          )

        "large" ->
          assign(
            assigns,
            name_class: "text-xl",
            score_box_class: "px-4 py-2.5",
            score_text_class: "text-2xl",
            status_size: "w-3.5 h-3.5"
          )
      end

    ~H"""
    <div class={ "bg-gray-900/80 rounded-lg  mb-4 shadow-xl backdrop-blur-md border border-gray-700/50 " <> @outer_class}>
      <div class="flex items-center justify-between">
        <div>
          <span class={@name_class <> " font-bold text-white flex items-center gap-2"}>
            <%= if @current_player do %>
              <.icon name="hero-bookmark-solid" class="text-yellow-500" />
            <% end %>
            <%= unless @is_online do %>
              <span class="loading loading-ball loading-sm bg-red-500"></span>
            <% end %>
            <span class="line-clamp-1" title={@player_name}>{@player_name}</span>
          </span>
        </div>
        <div class={"bg-gray-800 rounded-lg border border-gray-700 " <> @score_box_class}>
          <span class={"font-bold text-white " <> @score_text_class}>{@score}</span>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a card stack for a player in a card game UI.

  ## Attributes

  * `player_seat` - The seat number of the player whose cards should be displayed
  * `game` - The game state containing hands, phases, and other game information
  * `size` - The size of the card stack: "small", "medium", or "large" (default: "medium")

  ## Examples

      <.card_stack player_seat={1} game={@game} size="medium" />
  """
  attr :player_seat, :integer, required: true
  attr :game, :map, required: true
  # "small", "medium", or "large"
  attr :size, :string, default: "medium"
  @spec card_stack(card_stack_assigns()) :: Phoenix.LiveView.Rendered.t()
  def card_stack(assigns) do
    assigns =
      assigns
      |> assign(:hand, Map.get(assigns.game.hands, assigns.player_seat, []))
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
        |> assign(:fanHeight, 180)

      "large" ->
        assigns
        |> assign(:width, "w-full")
        |> assign(:fanHeight, 260)

      _medium ->
        assigns
        |> assign(:width, "w-full")
        |> assign(:fanHeight, 220)
    end
  end
end
