FROM alpine:3.10

RUN apk add --no-cache --no-progress curl jq

COPY entrypoint.sh /entrypoint.sh
CMD ["/bin/bash", "/entrypoint.sh"]
