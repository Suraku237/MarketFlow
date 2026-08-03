FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY src ./src
COPY openapi ./openapi

ENV PORT=8080
ENV JWT_SECRET=dev-only-change-me
ENV AUTH_SERVICE_URL=http://auth-service:3000
ENV INVENTORY_SERVICE_URL=http://inventory-service:4000
ENV RATE_LIMIT_WINDOW_MS=60000
ENV RATE_LIMIT_MAX=10

EXPOSE 8080

CMD ["node", "src/server.js"]
