// Consumes "enrollment.created" events published by academic-service and
// creates an invoice for each one — the Week 4 asynchronous workflow.
// Independent of academic-service: this runs whenever RabbitMQ delivers a
// message, on its own schedule, never blocking the enrollment request that
// originally triggered it.

const amqp = require('amqplib');
const { createInvoice } = require('../store');

const RABBITMQ_URL = process.env.RABBITMQ_URL || 'amqp://localhost:5672';
const EXCHANGE = 'school_events';
const QUEUE = 'invoice_creation_queue';
const ROUTING_KEY = 'enrollment.created';

async function connectWithRetry(retries = 10, delayMs = 3000) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const connection = await amqp.connect(RABBITMQ_URL);
      console.log('finance-service: connected to RabbitMQ');
      return connection;
    } catch (err) {
      console.warn(`finance-service: RabbitMQ connect attempt ${attempt} failed: ${err.message}`);
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }
  throw new Error('finance-service: could not connect to RabbitMQ after retries');
}

async function handleMessage(channel, msg) {
  if (!msg) return;

  try {
    const event = JSON.parse(msg.content.toString());
    const { data } = event;

    try {
      await createInvoice({
        studentId: data.studentId,
        enrollmentId: data.enrollmentId,
        amount: data.feeAmount,
      });
      console.log(`finance-service: created invoice for enrollment ${data.enrollmentId} (student ${data.studentId})`);
    } catch (err) {
      if (err.code === 'ER_DUP_ENTRY') {
        // invoices.enrollment_id is UNIQUE — this event was already
        // processed (RabbitMQ's at-least-once delivery can redeliver).
        // Treat as a successful no-op rather than an error.
        console.log(`finance-service: invoice already exists for enrollment ${data.enrollmentId}, skipping`);
      } else {
        throw err;
      }
    }

    channel.ack(msg);
  } catch (err) {
    console.error(`finance-service: failed to process message: ${err.message}`);
    // Redeliver once (in case the failure was transient, e.g. a momentary
    // DB blip); if it fails again after redelivery, drop it rather than
    // requeue forever.
    channel.nack(msg, false, !msg.fields.redelivered);
  }
}

async function startConsumer() {
  const connection = await connectWithRetry();
  const channel = await connection.createChannel();

  await channel.assertExchange(EXCHANGE, 'direct', { durable: true });
  await channel.assertQueue(QUEUE, { durable: true });
  await channel.bindQueue(QUEUE, EXCHANGE, ROUTING_KEY);
  await channel.prefetch(1);

  channel.consume(QUEUE, (msg) => handleMessage(channel, msg), { noAck: false });

  console.log(`finance-service: listening for "${ROUTING_KEY}" on queue "${QUEUE}"`);

  connection.on('error', (err) => console.error(`finance-service: RabbitMQ connection error: ${err.message}`));
  connection.on('close', () => {
    console.warn('finance-service: RabbitMQ connection closed, reconnecting...');
    setTimeout(() => startConsumer().catch((err) => console.error(err.message)), 3000);
  });
}

module.exports = { startConsumer };
