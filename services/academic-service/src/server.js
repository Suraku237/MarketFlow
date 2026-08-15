require('dotenv').config();
const { createApp } = require('./app');
const { startConnecting } = require('./events/publisher');

const PORT = process.env.PORT || 4000;

const app = createApp();

app.listen(PORT, () => {
  console.log(`academic-service listening on port ${PORT}`);
});

startConnecting();
