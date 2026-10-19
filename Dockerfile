FROM node:22-alpine

ENV NODE_ENV=production
ENV DATA_DIR=/data

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY --chown=node:node index.js ./
RUN mkdir -p /data && chown node:node /data

USER node

CMD ["node", "index.js"]
