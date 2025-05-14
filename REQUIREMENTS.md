SOFTWARE REQUIREMENTS SPECIFICATION (SRS)
Lora Card Game – Elixir / Phoenix LiveView – v 1.0‑draft

Scope: MVP implementation of the Serbian variant of Lora – 4 players, 32‑card deck, 7 fixed contracts, 28 deals – for desktop browsers. No database, no authentication, no monetization.

SCOPE
Implement a real‑time, browser‑based version of Lora for four players using Phoenix LiveView. All game state lives in memory (GenServer). The system must support at least 50 simultaneous matches on a single BEAM node.

DEFINITIONS AND ABBREVIATIONS
Term = Meaning
Contract = One of the seven sub‑games (Minimum, Maximum, Queens, Hearts, Jack of Clubs, King of Hearts plus Last Trick, Lora).
Deal = One hand: dealing 8 cards to each player and playing the contract.
Trick = A single trick in trick‑taking contracts.
Game = Full cycle of 28 deals (each of the 7 contracts times 4 dealers).

ACTORS
Player – joins a lobby by nickname and plays one active game.
System – server‑side GameServer (GenServer) that keeps state and validates moves.

FUNCTIONAL REQUIREMENTS

4.1 Lobby and Matchmaking
FR‑L‑01  A player can create a new game (6‑character code).
FR‑L‑02  A player can join an existing game by code while seats are fewer than four.
FR‑L‑03  The game auto‑starts when the fourth player joins; seat 1 becomes first dealer.

4.2 Game Lifecycle
FR‑G‑01  Generate and shuffle a 32‑card deck (A K Q J 10 9 8 7 in each suit).
FR‑G‑02  Each dealer deals seven consecutive contracts in the fixed order listed below.
FR‑G‑03  Contract order and scoring:

Minimum, plus one point per trick taken.

Maximum, minus one point per trick taken.

Queens, plus two points per queen taken.

Hearts, plus one point per heart taken; minus eight if one player takes all hearts.

Jack of Clubs, plus eight points to the player who takes it.

King of Hearts and Last Trick, plus four points each; plus eight if captured in the same trick.

Lora, minus eight to the first player who empties hand; all others receive plus one point per remaining card.
FR‑G‑04  After 28 deals compute total scores; the lowest score wins.

4.3 Trick‑Taking Contracts (1–6)
FR‑T‑01  Server maintains current_trick as a list of pairs (player seat, card).
FR‑T‑02  Play proceeds anticlockwise. Players must follow suit if possible. There are no trumps. The highest card of the led suit wins the trick. The rank order is A K Q J 10 9 8 7 except that 7 counts after Ace for sequences.
FR‑T‑03  At trick close the cards move to the winner’s pile. Scoring is applied at end of the deal.
FR‑T‑04  The client UI shows a player only the legal cards that may be played, as provided by the server.

4.4 Lora Contract
FR‑LORA‑01  Server maintains lora_layout as a map of suit to list of cards on the table.
FR‑LORA‑02  The first card played defines the starting rank. Sequences run rank, rank+1, … K, A, 7, 8.
FR‑LORA‑03  If a player holds no legal card they must pass; the pass is sent to the server for validation.
FR‑LORA‑04  The first player to empty hand receives minus eight points; every other player receives plus one point for each card left in hand.

4.5 Reconnection
FR‑R‑01  If the WebSocket connection drops for less than 30 seconds the player may rejoin and receive a full state snapshot.

NON‑FUNCTIONAL REQUIREMENTS

NFR‑P‑01  Use Elixir 1.17 or newer, Phoenix 1.8 or newer, LiveView 1.1 or newer.
NFR‑P‑02  No database. All state is held in GameServer and serialized into socket assigns for reconnection.
NFR‑P‑03  The server must push updates to all clients within 100 ms after a player action.
NFR‑P‑04  Support at least 50 concurrent matches (approximately 200 WebSocket connections) on one VM.
NFR‑Q‑01  Achieve at least 90 percent unit test coverage in Lora.* modules.
NFR‑Q‑02  Provide a GitHub Actions CI pipeline with formatter check, dialyzer, and tests.

ARCHITECTURE OVERVIEW
High level:
Phoenix Endpoint → LiveSocket → LobbyLive and GameLive views.
DynamicSupervisor named GameSupervisor starts one GameServer GenServer per match.
Phoenix PubSub distributes game events between GameServer and the LiveViews.
Presence tracks connected sockets per game code.

KEY MODULES
Lora.Deck – create and shuffle deck, card helpers.
Lora.GameServer – GenServer for lobby, state machine, move validation.
Lora.Game – pure functions for dealing, legal moves, scoring.
Lora.Contract – enum of the seven contracts.
Lora.Score – cumulative scoring helpers.
LoraWeb.LobbyLive – lobby user interface.
LoraWeb.GameLive – main game interface showing hands, trick area, scores.
LoraWeb.Presence – track sockets per game.

GameServer state structure
id: string
players: list of maps {id, name, seat, pid}
dealer_seat: integer 1 to 4
contract_index: integer 0 to 6
hands: map seat → list of cards
trick: list of tuples {seat, card}
taken: map seat → list of cards
lora_layout: map suit → list of cards
scores: map seat → integer
phase: one of :lobby, :playing, :finished

LIVEVIEW EVENT FLOW

On socket join the server pushes lobby_state to the client.

When four players are seated the server automatically starts the game and pushes the initial deal to all clients.

For each move the client sends "play_card" with card id.
a. GameLive forwards the message to GameServer.
b. On success the server broadcasts {:card_played, seat, card, new_state} to the match topic.

ACCEPTANCE CRITERIA (EXAMPLE)
Feature: Minimum contract scoring
Scenario: Player takes 3 tricks
Given a new game with contract Minimum
When player 1 wins three tricks
Then player 1’s score increases by three points

Similar test scenarios must exist for each contract, Lora finish, reconnect behaviour, and latency measurement.

OUT OF SCOPE
Mobile‑first layout
AI players
Persistence and save‑load of games
Variant rules such as bidding or three‑player mode
Authentication and authorization
In‑game chat or emojis

DELIVERABLES
Mix umbrella project named lora and lora_web
README with setup instructions and devcontainer.json
GitHub Actions workflow file ci.yml
Dockerfile for production release
Comprehensive ExUnit test suite covering contracts and scoring