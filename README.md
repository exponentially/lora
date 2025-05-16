# Lora Card Game

A real-time implementation of the Serbian card game Lora using Elixir and Phoenix LiveView.

## About the Game

Lora is a 4-player card game played with a 32-card deck (7, 8, 9, 10, J, Q, K, A in all four suits). The game consists of 28 deals with 7 different contracts (Minimum, Maximum, Queens, Hearts, Jack of Clubs, King of Hearts plus Last Trick, and Lora), each played 4 times with different dealers.

## Features

- Real-time multiplayer gameplay with Phoenix LiveView
- In-memory game state with GenServer
- 7 different contracts with unique rules
- Player reconnection support
- Responsive design for desktop browsers

## Requirements

- Elixir 1.17 or newer
- Phoenix 1.8 or newer
- Phoenix LiveView 1.1 or newer
- Node.js and npm for assets

## Development Setup

### Option 1: Local Setup

1. Install dependencies:

```bash
mix deps.get
cd apps/lora_web/assets && npm install && cd ../../..
```

2. Start the Phoenix server:

```bash
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Option 2: Using Dev Containers (Recommended)

This project includes a dev container configuration for Visual Studio Code, which provides a consistent development environment.

1. Install the [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension for VS Code.
2. Open the project folder in VS Code.
3. When prompted to "Reopen in Container", click "Reopen in Container".
4. Once the container is built and running, the development environment is ready.
5. Open a terminal in VS Code and start the Phoenix server:

```bash
mix phx.server
```

## Running Tests

```bash
mix test
```

For test coverage:

```bash
mix coveralls.html
```

## Deployment

### Using Docker

1. Build the Docker image:

```bash
docker build -t lora-game .
```

2. Run the container:

```bash
docker run -p 4000:4000 -e PHX_HOST=your-domain.com lora-game
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
