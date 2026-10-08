FROM alpine:3.20

RUN apk add --no-cache ca-certificates curl unzip \
 && mkdir -p /usr/local/bin /etc/xray \
 && curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
 && unzip /tmp/xray.zip xray -d /usr/local/bin \
 && chmod +x /usr/local/bin/xray \
 && rm /tmp/xray.zip

COPY config.json /etc/xray/config.json

EXPOSE 8080
CMD ["/usr/local/bin/xray", "run", "-c", "/etc/xray/config.json"]
