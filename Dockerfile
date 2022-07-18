FROM node:16-alpine3.11

WORKDIR /deploy-app/

RUN apk update
RUN apk upgrade

COPY ./package.json /deploy-app/
COPY ./yarn.lock /deploy-app/

RUN yarn install

COPY . /deploy-app/

CMD yarn start:dev
