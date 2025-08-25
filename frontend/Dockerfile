FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci || npm install
COPY . .
EXPOSE 5173
ENV VITE_API_BASE_URL="http://localhost:3000"
CMD ["npm", "run", "dev", "--", "--host"]
