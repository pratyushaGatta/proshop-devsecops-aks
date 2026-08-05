# Stage 1: Build React frontend
FROM node:20-alpine AS frontend-build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY frontend/package*.json ./frontend/
RUN npm ci --prefix frontend

COPY frontend ./frontend
RUN npm run build --prefix frontend

# Stage 2: Production image
FROM node:20-alpine

WORKDIR /app

ENV NODE_ENV=production

COPY package*.json ./
RUN npm ci --omit=dev

COPY backend ./backend
COPY uploads ./uploads

COPY --from=frontend-build /app/frontend/build ./frontend/build

EXPOSE 5000

CMD ["node", "backend/server.js"]