FROM alpine:latest

RUN apk update && apk add --no-cache python3 openssh shadow && \
    adduser -D -s /bin/sh alex && \
    ( echo 'alex:alex' | chpasswd ) && \
    sed -i 's|#PermitRootLogin|PermitRootLogin no\n\0|g' /etc/ssh/sshd_config && \
    sed -i 's|#PasswordAuthentication yes|PasswordAuthentication yes|g' /etc/ssh/sshd_config && \
    echo "AllowUsers alex" >> /etc/ssh/sshd_config && \
    echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config && \
    echo "GatewayPorts yes" >> /etc/ssh/sshd_config && \
    echo "PermitTunnel yes" >> /etc/ssh/sshd_config

COPY relay.py /relay.py

EXPOSE 8080

CMD sh -c '( cd /etc/ssh && ssh-keygen -A ) && \
    /usr/sbin/sshd -f /etc/ssh/sshd_config && \
    python3 /relay.py'
