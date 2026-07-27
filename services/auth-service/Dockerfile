FROM node:20-alpine

WORKDIR /app

# better-sqlite3 compiles a native addon on install
RUN apk add --no-cache python3 make g++

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY src ./src

# Sane defaults so the container runs standalone with a single `docker run`;
# override JWT_SECRET (and anything else) with --env-file or -e in real deployments.
ENV PORT=3000
ENV JWT_SECRET=dev-only-change-me
ENV JWT_EXPIRES_IN=1h
# Points at the volume mounted by docker-compose.yml (../../database on the
# host); override if you mount the shared database folder somewhere else.
ENV DB_PATH=/app/database/smartstock.db

EXPOSE 3000

CMD ["node", "src/server.js"]