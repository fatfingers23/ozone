FROM node:24.22.1-alpine3.23 AS build

WORKDIR /usr/src/ozone

RUN corepack enable

COPY package.json yarn.lock .yarnrc.yml ./
RUN yarn
COPY . .
RUN yarn build
RUN rm -rf node_modules .next/cache
RUN mv service/package.json package.json && mv service/yarn.lock yarn.lock
RUN yarn

# final stage

FROM node:24.22.1-alpine3.23

RUN apk add --update dumb-init
ENV TZ=Etc/UTC

WORKDIR /usr/src/ozone
COPY --from=build /usr/src/ozone /usr/src/ozone
RUN chown -R node:node .

ENTRYPOINT ["dumb-init", "--"]
EXPOSE 3000
ENV OZONE_PORT=3000
ENV NODE_ENV=production
HEALTHCHECK --interval=10s --timeout=3s --retries=3 --start-period=10s \
  CMD ["node", "-e", "fetch('http://127.0.0.1:' + (process.env.OZONE_PORT || '3000') + '/xrpc/_health', { signal: AbortSignal.timeout(2500) }).then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]
USER node
CMD ["node", "./service"]

LABEL org.opencontainers.image.source=https://github.com/eurosky-social/ozone
LABEL org.opencontainers.image.description="Ozone Moderation Service Web UI (eurosky fork)"
LABEL org.opencontainers.image.licenses=MIT
