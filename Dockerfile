FROM alpine:3.13.4

RUN apk add --no-cache --no-progress curl jq bash

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
