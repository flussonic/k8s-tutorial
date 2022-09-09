FROM node:18-alpine
WORKDIR /usr/src/app
LABEL maintainer="Flussonic team <support@flussonic.com>"
COPY package.json .
RUN yarn install --prod
COPY logger.mjs ./logger.mjs
CMD node logger.mjs

