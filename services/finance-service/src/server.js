require('dotenv').config();
const { createApp } = require('./app');
const { startConsumer } = require('./events/consumer');

const PORT = process.env.PORT || 4001;

const app = createApp();

app.listen(PORT, () => {
  console.log(`finance-service listening on port ${PORT}`);
});

startConsumer().catch((err) => {
  console.error(`finance-service: failed to start RabbitMQ consumer: ${err.message}`);
});
