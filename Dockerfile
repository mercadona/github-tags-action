FROM alpine:3.10

COPY script.sh /script.sh

RUN apk update && apk add bash git curl jq

ENTRYPOINT ["sh", "/script.sh"]
