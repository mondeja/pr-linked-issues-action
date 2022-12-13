FROM alpine:3.17

RUN apk add --no-cache --no-progress curl jq

COPY entrypoint /entrypoint
ENTRYPOINT ["sh", "/entrypoint"]
