const WebSocket = require('ws');
const server = new WebSocket.Server({ port: 4000 });

let gameState = {
  backgroundColors: [],
  score: 0,
  highScore: 0,
};

let clients = [];
let interval = 2000; // change 1 button to green every interval (ms)

server.on('connection', (ws) => {
  console.log('New client connected');
  const clientIndex = clients.length + 1; // Start client index from 1
  clients.push(ws);
  gameState.backgroundColors.push('red');

  // Send initial game state to the new client
  ws.send(JSON.stringify({ ...gameState, clientIndex }));

  ws.on('message', (message) => {
    const data = JSON.parse(message);
    const index = data.index - 1; // Adjust index to match array position
    if (index !== undefined && gameState.backgroundColors[index] === 'green') {
      gameState.backgroundColors[index] = 'red';
      gameState.score++;
      if (gameState.score > gameState.highScore) {
        gameState.highScore = gameState.score;
      }
      console.log(`Button ${data.index} tapped. Score: ${gameState.score}`);

      // Broadcast updated game state to all clients
      broadcast(JSON.stringify(gameState));
    }
  });

  // Remove client when they disconnect
  ws.on('close', () => {
    console.log('Client disconnected');
    clients = clients.filter((client) => client !== ws);
    gameState.backgroundColors.splice(clientIndex - 1, 1); // Adjust index to match array position
    broadcast(JSON.stringify(gameState));
  });
});

// Broadcast messages to all connected clients
function broadcast(message) {
  clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

// Randomly turns one button green every 2 seconds
setInterval(() => {
  if (clients.length > 0) {
    const newIndex = Math.floor(Math.random() * clients.length);
    gameState.backgroundColors = Array(clients.length).fill('red');
    gameState.backgroundColors[newIndex] = 'green';
    console.log(`Button ${newIndex + 1} turned green`); // Adjust index for logging
    broadcast(JSON.stringify(gameState));
  }
}, interval);

console.log('WebSocket server running on ws://localhost:4000');