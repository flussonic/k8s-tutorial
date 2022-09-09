FROM node:18-alpine
WORKDIR /usr/src/app
LABEL maintainer="Flussonic Team <support@flussonic.com>"
COPY package.json .
RUN yarn install --prod
COPY index.mjs ./index.mjs
CMD node index.mjs

