// Publishes "enrollment.created" events to RabbitMQ so finance-service can
// create an invoice asynchronously. Deliberately fire-and-forget: a
// down/unreachable RabbitMQ must never fail an enrollment request — this
// module swallows its own connection/publish errors and just logs them,
// the enrollment HTTP response always returns based on the MySQL commit
// alone.

const amqp = require('amqplib');
const { randomUUID } = require('crypto');

const RABBITMQ_URL = process.env.RABBITMQ_URL || 'amqp://localhost:5672';
const EXCHANGE = 'school_events';
const ROUTING_KEY = 'enrollment.created';

let channelPromise = null;

async function connectWithRetry(retries = 10, delayMs = 3000) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const connection = await amqp.connect(RABBITMQ_URL);
      const channel = await connection.createChannel();
      await channel.assertExchange(EXCHANGE, 'direct', { durable: true });
      connection.on('error', () => { channelPromise = null; });
      connection.on('close', () => { channelPromise = null; });
      console.log('academic-service: connected to RabbitMQ');
      return channel;
    } catch (err) {
      console.warn(`academic-service: RabbitMQ connect attempt ${attempt} failed: ${err.message}`);
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }
  channelPromise = null;
  throw new Error('academic-service: could not connect to RabbitMQ after retries');
}

function getChannel() {
  if (!channelPromise) {
    channelPromise = connectWithRetry().catch((err) => {
      channelPromise = null;
      throw err;
    });
  }
  return channelPromise;
}

// Called once at startup so the connection is already warm by the time the
// first enrollment happens, without making server boot wait on it.
function startConnecting() {
  getChannel().catch(() => {
    // Already logged in connectWithRetry; nothing more to do here. A later
    // publishEnrollmentCreated() call will retry via getChannel() again.
  });
}

async function publishEnrollmentCreated(enrollment) {
  try {
    const channel = await getChannel();
    const payload = {
      eventId: randomUUID(),
      eventType: 'enrollment.created',
      occurredAt: new Date().toISOString(),
      data: {
        enrollmentId: enrollment.enrollment_id,
        studentId: enrollment.student_id,
        studentName: enrollment.student_name,
        studentEmail: enrollment.student_email,
        courseId: enrollment.course_id,
        courseCode: enrollment.course_code,
        courseName: enrollment.course_name,
        feeAmount: enrollment.fee_amount,
        term: enrollment.term,
      },
    };
    channel.publish(EXCHANGE, ROUTING_KEY, Buffer.from(JSON.stringify(payload)), { persistent: true });
    console.log(`academic-service: published enrollment.created for enrollment ${enrollment.enrollment_id}`);
  } catch (err) {
    console.warn(`academic-service: failed to publish enrollment.created: ${err.message}`);
  }
}

module.exports = { startConnecting, publishEnrollmentCreated };
