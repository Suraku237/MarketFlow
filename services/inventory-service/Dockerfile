FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY src ./src

ENV PORT=4000
ENV JWT_SECRET=dev-only-change-me
ENV DB_HOST=localhost
ENV DB_PORT=3306
ENV DB_USER=root
ENV DB_PASSWORD=dev-only-change-me
ENV DB_NAME=smartstock

EXPOSE 4000

CMD ["node", "src/server.js"]
