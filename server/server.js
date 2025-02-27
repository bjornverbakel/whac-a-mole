const WebSocket = require('ws');
const server = new WebSocket.Server({ port: 4000 });

let gameState = {
  backgroundColors: [],
  score: 0,
  highScore: 0,
};

let clients = [];

server.on('connection', (ws) => {
  console.log('New client connected');
  const clientIndex = clients.length;
  clients.push(ws);
  gameState.backgroundColors.push('red');

  // Send initial game state to the new client
  ws.send(JSON.stringify({ ...gameState, clientIndex }));

  ws.on('message', (message) => {
    const data = JSON.parse(message);
    if (data.index !== undefined && gameState.backgroundColors[data.index] === 'green') {
      gameState.backgroundColors[data.index] = 'red';
      gameState.score++;
      if (gameState.score > gameState.highScore) {
        gameState.highScore = gameState.score;
      }
      console.log(`Button ${data.index} tapped. Score: ${gameState.score}`);

      // Broadcast updated game state to all clients
      broadcast(JSON.stringify(gameState));
    }
  });

  ws.on('close', () => {
    console.log('Client disconnected');
    clients = clients.filter((client) => client !== ws);
    gameState.backgroundColors.splice(clientIndex, 1);
    broadcast(JSON.stringify(gameState));
  });
});

// Function to broadcast messages to all connected clients
function broadcast(message) {
  clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

// Game logic: Randomly turn one button green every 2 seconds
setInterval(() => {
  if (clients.length > 0) {
    const newIndex = Math.floor(Math.random() * clients.length);
    gameState.backgroundColors = Array(clients.length).fill('red');
    gameState.backgroundColors[newIndex] = 'green';
    console.log(`Button ${newIndex} turned green`);
    broadcast(JSON.stringify(gameState));
  }
}, 2000);

console.log('WebSocket server running on ws://192.168.131.182:4000');
