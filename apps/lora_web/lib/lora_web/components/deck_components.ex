defmodule LoraWeb.DeckCompoents do
  @moduledoc """
    Playing card liveview compoents
  """
  use Phoenix.Component
  use Gettext, backend: LoraWeb.Gettext
  use LoraWeb, :verified_routes

  @doc """
  Renders HTML fornt of card.
  Finds image from static images /images/fronts/\#{suit}_\#{rank}.svg
  """
  attr :backend, :atom, default: :svg
  attr :suit, :atom, required: true
  attr :rank, :atom, required: true
  attr :size, :string, default: "medium"
  attr :class, :string, default: ""

  def card_front_html(assigns) do
    assigns =
      assigns
      |> assign_stack_styles()

    ~H"""
    <div class={"card-stacked relative #{@card_height} #{@card_width} rounded-lg border-2 flex items-center justify-center #{LoraWeb.CardUtils.suit_color(@suit)} " <> @class}>
      <div class={"card-value text-#{@value_size} #{LoraWeb.CardUtils.suit_color(@suit)}"}>
        {LoraWeb.CardUtils.format_suit(@suit)}
      </div>
      <span class={"card-corner top-left font-bold text-#{@corner_size} #{LoraWeb.CardUtils.suit_color(@suit)}"}>
        <span class="card-rank">{LoraWeb.CardUtils.format_rank(@rank)}</span>
        <br />
        <span class="card-suit">{LoraWeb.CardUtils.format_suit(@suit)}</span>
      </span>
      <span class={"card-corner bottom-right font-bold text-#{@corner_size} #{LoraWeb.CardUtils.suit_color(@suit)}"}>
        <span class="card-rank">{LoraWeb.CardUtils.format_rank(@rank)}</span>
        <br />
        <span class="card-suit">{LoraWeb.CardUtils.format_suit(@suit)}</span>
      </span>
    </div>
    """
  end

  @doc """
  Renders HTML fornt of card.
  Finds image from static images /images/fronts/\#{suit}_\#{rank}.svg
  """
  attr :image, :string, default: "blue2.svg"
  attr :size, :string, default: "medium"
  attr :class, :string, default: ""

  def card_back(assigns) do
    assigns =
      assigns
      |> assign_stack_styles()

    ~H"""
    <div
      class={"card-stacked relative #{@card_height} #{@card_width} rounded-lg border-0 flex p-0 items-center justify-center bg-transparent " <> @class}
      style={"background-image: url(#{~p"/images/backs/#{@image}"}); background-size: contain; background-repeat: no-repeat; background-color: transparent;"}
    >
    </div>
    """
  end

  @doc """
  Renders HTML fornt of card.
  Finds image from static images /images/fronts/\#{suit}_\#{rank}.svg
  """
  attr :backend, :atom, default: :svg
  attr :suit, :atom, required: true
  attr :rank, :atom, required: true
  attr :size, :string, default: "medium"
  attr :class, :string, default: ""
  attr :id, :string, default: nil

  def card_front(assigns) do
    assigns =
      assigns
      |> assign(:image, "#{assigns.suit}_#{assigns.rank}.svg")
      |> assign_stack_styles()

    ~H"""
    <div
      id={@id}
      class={"card-stacked relative #{@card_height} #{@card_width} rounded-lg border-0 flex p-0 items-center justify-center bg-transparent " <> @class}
      style={"background-image: url(#{~p"/images/fronts/#{@image}"}); background-size: contain; background-repeat: no-repeat; background-color: transparent;"}
    >
    </div>
    """
  end

  defp assign_stack_styles(assigns) do
    case assigns.size do
      "small" ->
        assigns
        |> assign(:card_width, "w-24")
        |> assign(:card_height, "h-36")
        |> assign(:text_size, "text-xl")
        |> assign(:corner_size, "base")
        |> assign(:value_size, "xl")

      "medium" ->
        assigns
        |> assign(:card_width, "w-28")
        |> assign(:card_height, "h-40")
        |> assign(:text_size, "text-2xl")
        |> assign(:corner_size, "lg")
        |> assign(:value_size, "2xl")

      "large" ->
        assigns
        |> assign(:card_width, "w-32")
        |> assign(:card_height, "h-52")
        |> assign(:text_size, "text-3xl")
        |> assign(:corner_size, "xl")
        |> assign(:value_size, "3xl")
    end
  end
end
