FROM alpine:3.18

RUN apk --no-cache add --update apk-cron curl jq && rm -rf /var/cache/apk/*

ADD crontab.txt /crontab.txt
ADD updaterScript.sh /updaterScript.sh
COPY entry.sh /entry.sh
RUN chmod 755 /updaterScript.sh /entry.sh
RUN /usr/bin/crontab /crontab.txt

CMD ["/entry.sh"]
