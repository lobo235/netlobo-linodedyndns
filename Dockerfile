FROM alpine:3.18

RUN apk --no-cache add --update curl jq && rm -rf /var/cache/apk/*

ADD updaterScript.sh /updaterScript.sh
COPY entry.sh /entry.sh
RUN chmod 755 /updaterScript.sh /entry.sh

CMD ["/entry.sh"]
