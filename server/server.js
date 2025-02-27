const express = require('express');
const http = require('http');
const socketIo = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

let gameState = {
  backgroundColors: ['red', 'red', 'red'],
  score: 0,
  highScore: 0,
};

io.on('connection', (socket) => {
  console.log('New client connected');
  socket.emit('gameState', gameState);

  socket.on('tap', (data) => {
    const index = data.index;
    if (gameState.backgroundColors[index] === 'green') {
      gameState.backgroundColors[index] = 'red';
      gameState.score++;
      if (gameState.score > gameState.highScore) {
        gameState.highScore = gameState.score;
      }
      console.log(`Button ${index} tapped. Score: ${gameState.score}`);
      io.emit('gameState', gameState);
    }
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected');
  });
});

// Periodically change a random button to green
setInterval(() => {
  const newIndex = Math.floor(Math.random() * 3);
  gameState.backgroundColors = ['red', 'red', 'red'];
  gameState.backgroundColors[newIndex] = 'green';
  console.log(`Button ${newIndex} turned green`);
  io.emit('gameState', gameState);
}, 2000); // Change every 2 seconds

server.listen(4000, () => console.log('Server is running on port 4000'));