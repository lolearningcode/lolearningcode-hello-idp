# backstage/Dockerfile
FROM node:18-slim

WORKDIR /app

COPY . .

RUN yarn install --frozen-lockfile
RUN yarn tsc
RUN yarn build:backend

CMD ["yarn", "start"]