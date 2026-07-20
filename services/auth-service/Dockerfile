FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY src ./src

# Sane defaults so the container runs standalone with a single `docker run`;
# override JWT_SECRET (and anything else) with --env-file or -e in real deployments.
ENV PORT=3000
ENV JWT_SECRET=dev-only-change-me
ENV JWT_EXPIRES_IN=1h

EXPOSE 3000

CMD ["node", "src/server.js"]
