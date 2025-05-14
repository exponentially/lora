defmodule Lora.Game do
  @moduledoc """
  Core game logic for Lora, implementing pure functions for dealing,
  checking legal moves, and processing game state.
  """

  alias Lora.{Deck, Contract, Score}

  @type player :: %{
    id: binary(),
    name: binary(),
    seat: integer()
  }

  @type game_state :: %{
    id: binary(),
    players: [player()],
    dealer_seat: integer(),
    contract_index: integer(),
    hands: %{integer() => [Deck.card()]},
    trick: [{integer(), Deck.card()}],
    taken: %{integer() => [[Deck.card()]]},
    lora_layout: %{Deck.suit() => [Deck.card()]},
    scores: %{integer() => integer()},
    phase: :lobby | :playing | :finished,
    current_player: integer(),
    dealt_count: integer()
  }

  @doc """
  Creates a new game with the given ID.
  """
  @spec new_game(binary()) :: game_state()
  def new_game(id) do
    %{
      id: id,
      players: [],
      dealer_seat: 1,
      contract_index: 0,
      hands: %{},
      trick: [],
      taken: %{},
      lora_layout: %{},
      scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0},
      phase: :lobby,
      current_player: nil,
      dealt_count: 0
    }
  end

  @doc """
  Adds a player to the game.
  Returns {:ok, updated_state} if successful, or {:error, reason} if not.
  """
  @spec add_player(game_state(), binary(), binary()) :: {:ok, game_state()} | {:error, binary()}
  def add_player(state, player_id, player_name) do
    cond do
      state.phase != :lobby ->
        {:error, "Cannot join a game that has already started"}

      Enum.any?(state.players, fn p -> p.id == player_id end) ->
        {:error, "Player already in game"}

      length(state.players) >= 4 ->
        {:error, "Game is full"}

      true ->
        seat = length(state.players) + 1
        player = %{id: player_id, name: player_name, seat: seat}
        updated_state = %{state | players: state.players ++ [player]}

        # Start the game if we now have 4 players
        if length(updated_state.players) == 4 do
          {:ok, start_game(updated_state)}
        else
          {:ok, updated_state}
        end
    end
  end

  @doc """
  Start the game by dealing the first contract.
  """
  @spec start_game(game_state()) :: game_state()
  def start_game(state) do
    # First dealer is seat 1
    deal_new_contract(
      %{state |
        phase: :playing,
        dealer_seat: 1,
        contract_index: 0,
        dealt_count: 0
      }
    )
  end

  @doc """
  Deals a new contract.
  """
  @spec deal_new_contract(game_state()) :: game_state()
  def deal_new_contract(state) do
    contract = Contract.at(state.contract_index)

    # Create and shuffle new deck
    deck = Deck.new() |> Deck.shuffle()

    # Deal 8 cards to each player
    hands = Deck.deal(deck, 4)

    # The player to the right of the dealer leads
    first_player = next_seat(state.dealer_seat)

    state = %{state |
      hands: hands,
      trick: [],
      taken: %{1 => [], 2 => [], 3 => [], 4 => []},
      lora_layout: %{clubs: [], diamonds: [], hearts: [], spades: []},
      current_player: first_player,
      dealt_count: state.dealt_count + 1
    }

    # For Lora contract, we don't use tricks
    if contract == :lora do
      state
    else
      state
    end
  end

  @doc """
  Plays a card from a player's hand.
  Returns {:ok, new_state} or {:error, reason}
  """
  @spec play_card(game_state(), integer(), Deck.card()) :: {:ok, game_state()} | {:error, binary()}
  def play_card(state, seat, card) do
    cond do
      state.phase != :playing ->
        {:error, "Game is not in playing phase"}

      seat != state.current_player ->
        {:error, "Not your turn"}

      not card_in_hand?(state.hands[seat], card) ->
        {:error, "Card not in hand"}

      not is_legal_move?(state, seat, card) ->
        {:error, "Illegal move"}

      true ->
        # Remove the card from the player's hand
        hands = Map.update!(state.hands, seat, fn hand ->
          hand -- [card]
        end)

        contract = Contract.at(state.contract_index)

        if Contract.trick_taking?(contract) do
          play_trick_taking_card(state, seat, card, hands)
        else
          play_lora_card(state, seat, card, hands)
        end
    end
  end

  @doc """
  Handles playing a card in a trick-taking contract.
  """
  @spec play_trick_taking_card(game_state(), integer(), Deck.card(), map()) :: {:ok, game_state()}
  def play_trick_taking_card(state, seat, card, hands) do
    # Add the card to the current trick
    updated_trick = state.trick ++ [{seat, card}]

    # Check if the trick is complete (all 4 players have played)
    if length(updated_trick) == 4 do
      # Determine the winner of the trick
      winner_seat = Deck.trick_winner(updated_trick)

      # Add the cards from the trick to the winner's taken pile
      taken = Map.update!(state.taken, winner_seat, fn taken_cards ->
        trick_cards = Enum.map(updated_trick, fn {_seat, card} -> card end)
        taken_cards ++ [trick_cards]
      end)

      # Check if the deal is over (all cards played)
      if Enum.all?(hands, fn {_seat, hand} -> hand == [] end) do
        # Deal is over, calculate scores
        deal_over_state = handle_deal_over(state, hands, taken, winner_seat)
        {:ok, deal_over_state}
      else
        # Continue with the next trick, winner leads
        {:ok, %{state |
          hands: hands,
          trick: [],
          taken: taken,
          current_player: winner_seat
        }}
      end
    else
      # Continue with the next player
      next_player = next_seat(seat)
      {:ok, %{state | hands: hands, trick: updated_trick, current_player: next_player}}
    end
  end

  @doc """
  Handles playing a card in the Lora contract.
  """
  @spec play_lora_card(game_state(), integer(), Deck.card(), map()) :: {:ok, game_state()}
  def play_lora_card(state, seat, {suit, rank}, hands) do
    # Add the card to the lora layout
    lora_layout = Map.update!(state.lora_layout, suit, fn cards -> cards ++ [{suit, rank}] end)

    # Check if the player has emptied their hand
    if hands[seat] == [] do
      # This player has won Lora
      deal_over_state = handle_lora_winner(state, hands, seat)
      {:ok, deal_over_state}
    else
      # Find the next player who can play
      {next_player, can_anyone_play} = find_next_player_who_can_play(state, hands, seat)

      if can_anyone_play do
        {:ok, %{state |
          hands: hands,
          lora_layout: lora_layout,
          current_player: next_player
        }}
      else
        # No one can play, the deal is over
        deal_over_state = handle_lora_winner(state, hands, seat)
        {:ok, deal_over_state}
      end
    end
  end

  @doc """
  Pass in the Lora contract when a player has no legal moves.
  """
  @spec pass_lora(game_state(), integer()) :: {:ok, game_state()} | {:error, binary()}
  def pass_lora(state, seat) do
    contract = Contract.at(state.contract_index)

    cond do
      state.phase != :playing ->
        {:error, "Game is not in playing phase"}

      seat != state.current_player ->
        {:error, "Not your turn"}

      contract != :lora ->
        {:error, "Can only pass in the Lora contract"}

      has_legal_move?(state, seat) ->
        {:error, "You have legal moves available"}

      true ->
        # Find the next player who can play
        {next_player, can_anyone_play} = find_next_player_who_can_play(state, state.hands, seat)

        if can_anyone_play do
          {:ok, %{state | current_player: next_player}}
        else
          # No one can play, the deal is over - find the player with the fewest cards
          {winner, _} =
            state.hands
            |> Enum.min_by(fn {_seat, cards} -> length(cards) end)

          deal_over_state = handle_lora_winner(state, state.hands, winner)
          {:ok, deal_over_state}
        end
    end
  end

  @doc """
  Find the next player who can make a legal move in Lora.
  Returns {next_player_seat, true} if found, or {nil, false} if no one can play.
  """
  @spec find_next_player_who_can_play(game_state(), map(), integer()) :: {integer() | nil, boolean()}
  def find_next_player_who_can_play(state, hands, current_seat) do
    # Try each player in order
    Enum.reduce_while(1..4, {nil, false}, fn _, _ ->
      next_seat = next_seat(current_seat)

      if has_legal_move?(state, next_seat) do
        {:halt, {next_seat, true}}
      else
        if next_seat == current_seat do
          # We've checked all players and come back to the start
          {:halt, {nil, false}}
        else
          {:cont, {nil, false}}
        end
      end
    end)
  end

  @doc """
  Handle the end of a deal in trick-taking contracts.
  """
  @spec handle_deal_over(game_state(), map(), map(), integer()) :: game_state()
  def handle_deal_over(state, hands, taken, last_trick_winner) do
    contract = Contract.at(state.contract_index)

    # Calculate scores for this contract
    contract_scores = case contract do
      :minimum -> Score.minimum(taken)
      :maximum -> Score.maximum(taken)
      :queens -> Score.queens(flatten_taken_cards(taken))
      :hearts -> Score.hearts(flatten_taken_cards(taken))
      :jack_of_clubs -> Score.jack_of_clubs(flatten_taken_cards(taken))
      :king_hearts_last_trick -> Score.king_hearts_last_trick(flatten_taken_cards(taken), last_trick_winner)
      _ -> %{}
    end

    # Update cumulative scores
    updated_scores = Score.update_cumulative_scores(state.scores, contract_scores)

    # Check if the game is over
    if game_over?(state) do
      %{state |
        hands: hands,
        taken: taken,
        scores: updated_scores,
        phase: :finished
      }
    else
      # Move to the next contract or dealer
      {next_dealer, next_contract} = next_dealer_and_contract(state)

      # Deal the next contract
      deal_new_contract(%{state |
        dealer_seat: next_dealer,
        contract_index: next_contract,
        scores: updated_scores
      })
    end
  end

  @doc """
  Handle the winner of a Lora contract.
  """
  @spec handle_lora_winner(game_state(), map(), integer()) :: game_state()
  def handle_lora_winner(state, hands, winner_seat) do
    # Calculate Lora scores
    contract_scores = Score.lora(hands, winner_seat)

    # Update cumulative scores
    updated_scores = Score.update_cumulative_scores(state.scores, contract_scores)

    # Check if the game is over
    if game_over?(state) do
      %{state |
        hands: hands,
        scores: updated_scores,
        phase: :finished
      }
    else
      # Move to the next contract or dealer
      {next_dealer, next_contract} = next_dealer_and_contract(state)

      # Deal the next contract
      deal_new_contract(%{state |
        dealer_seat: next_dealer,
        contract_index: next_contract,
        scores: updated_scores
      })
    end
  end

  @doc """
  Flattens the taken cards structure for scoring.
  Converts %{seat => [[cards]]} to %{seat => [all_cards]}
  """
  @spec flatten_taken_cards(%{integer() => [[Deck.card()]]}) :: %{integer() => [Deck.card()]}
  def flatten_taken_cards(taken) do
    taken
    |> Map.new(fn {seat, tricks} ->
      {seat, List.flatten(tricks)}
    end)
  end

  @doc """
  Determines the next dealer and contract for a new deal.
  """
  @spec next_dealer_and_contract(game_state()) :: {integer(), integer()}
  def next_dealer_and_contract(state) do
    # Each dealer deals all 7 contracts before moving to the next dealer
    next_contract = rem(state.contract_index + 1, 7)

    if next_contract == 0 do
      # Move to the next dealer
      {next_seat(state.dealer_seat), 0}
    else
      # Same dealer, next contract
      {state.dealer_seat, next_contract}
    end
  end

  @doc """
  Determines if the game is over (28 deals played).
  """
  @spec game_over?(game_state()) :: boolean()
  def game_over?(state) do
    state.dealt_count >= 28
  end

  @doc """
  Returns whether a card is in the player's hand.
  """
  @spec card_in_hand?([Deck.card()], Deck.card()) :: boolean()
  def card_in_hand?(hand, card) do
    Enum.member?(hand, card)
  end

  @doc """
  Checks if the move is legal based on the current contract and game state.
  """
  @spec is_legal_move?(game_state(), integer(), Deck.card()) :: boolean()
  def is_legal_move?(state, seat, card = {suit, rank}) do
    contract = Contract.at(state.contract_index)
    hand = state.hands[seat]

    case contract do
      # For trick-taking contracts
      contract when contract != :lora ->
        case state.trick do
          # First card in trick can be anything
          [] -> true

          # Otherwise must follow suit if possible
          [{_, {led_suit, _}} | _] ->
            if Deck.has_suit?(hand, led_suit) do
              suit == led_suit
            else
              # If no cards of the led suit, can play anything
              true
            end
        end

      # For Lora contract
      :lora ->
        layout = state.lora_layout

        # If this is the first card played in Lora, any card is legal
        if Enum.all?(layout, fn {_, cards} -> cards == [] end) do
          true
        else
          # Check if card follows layout rules
          suit_layout = layout[suit]

          case suit_layout do
            # No cards of this suit played yet, check if valid starting rank
            [] ->
              # Any card can start a new suit if it's the same rank as a card already on the layout
              any_laid_card =
                layout
                |> Map.values()
                |> List.flatten()
                |> Enum.find(fn _ -> true end)

              case any_laid_card do
                nil -> true  # No cards played yet
                {_, first_rank} -> rank == first_rank  # Must match the first played card's rank
              end

            # Cards of this suit already played, card must be the next in sequence
            cards ->
              {_, last_rank} = List.last(cards)
              rank == Deck.next_rank_lora(last_rank)
          end
        end
    end
  end

  @doc """
  Checks if the player has any legal moves available.
  """
  @spec has_legal_move?(game_state(), integer()) :: boolean()
  def has_legal_move?(state, seat) do
    hand = state.hands[seat]
    Enum.any?(hand, &is_legal_move?(state, seat, &1))
  end

  @doc """
  Gets the next seat in play order (anticlockwise).
  """
  @spec next_seat(integer()) :: integer()
  def next_seat(seat) do
    rem(seat, 4) + 1
  end
end
