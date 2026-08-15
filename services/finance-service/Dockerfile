FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY src ./src

ENV PORT=4001
ENV JWT_SECRET=dev-only-change-me
ENV DB_HOST=localhost
ENV DB_PORT=3306
ENV DB_USER=root
ENV DB_PASSWORD=dev-only-change-me
ENV DB_NAME=smartschool
ENV RABBITMQ_URL=amqp://localhost:5672

EXPOSE 4001

CMD ["node", "src/server.js"]
