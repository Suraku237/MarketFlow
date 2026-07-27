FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY src ./src

# Sane defaults so the container runs standalone with a single `docker run`;
# override JWT_SECRET/DB_* (and anything else) with --env-file or -e in real
# deployments. docker-compose.yml overrides DB_HOST to point at the `db`
# service instead of localhost.
ENV PORT=3000
ENV JWT_SECRET=dev-only-change-me
ENV JWT_EXPIRES_IN=1h
ENV DB_HOST=localhost
ENV DB_PORT=3306
ENV DB_USER=root
ENV DB_PASSWORD=dev-only-change-me
ENV DB_NAME=smartstock

EXPOSE 3000

CMD ["node", "src/server.js"]
