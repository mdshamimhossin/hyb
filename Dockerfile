FROM alpine:latest

RUN apk update && apk add --no-cache python3 openssh shadow && \
    adduser -D -s /bin/sh alex && \
    ( echo 'alex:alex' | chpasswd ) && \
    sed -i 's|#PermitRootLogin|PermitRootLogin no\n\0|g' /etc/ssh/sshd_config && \
    sed -i 's|#PasswordAuthentication yes|PasswordAuthentication yes|g' /etc/ssh/sshd_config && \
    echo "AllowUsers alex" >> /etc/ssh/sshd_config && \
    echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config && \
    echo "GatewayPorts yes" >> /etc/ssh/sshd_config && \
    echo "PermitTunnel yes" >> /etc/ssh/sshd_config && \
    echo "KexAlgorithms +diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1" >> /etc/ssh/sshd_config && \
    echo "HostKeyAlgorithms +ssh-rsa" >> /etc/ssh/sshd_config && \
    echo "Ciphers +aes128-cbc,aes192-cbc,aes256-cbc" >> /etc/ssh/sshd_config && \
    echo "MACs +hmac-sha1" >> /etc/ssh/sshd_config

COPY relay.py /relay.py

EXPOSE 8080

# sshd start kora hocche background e, error thakleo eta container start ke block korbe na.
# python3 relay.py shobshomoy $PORT e bind korbe, tai Cloud Run health check pass korbei.
CMD sh -c '( cd /etc/ssh && ssh-keygen -A ) ; \
    echo "=== sshd config test ===" ; \
    /usr/sbin/sshd -t -f /etc/ssh/sshd_config ; \
    echo "=== starting sshd ===" ; \
    /usr/sbin/sshd -f /etc/ssh/sshd_config ; \
    echo "sshd exit code: $?" ; \
    echo "=== starting relay (binds PORT) ===" ; \
    exec python3 /relay.py'
