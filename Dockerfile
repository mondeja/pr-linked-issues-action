FROM alpine:3.13.5

RUN apk add --no-cache --no-progress curl jq bash

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
