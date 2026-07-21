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
    echo "KexAlgorithms +diffie-hellman-group14-sha1,diffie-hellman-group1-sha1,diffie-hellman-group-exchange-sha1,diffie-hellman-group-exchange-sha256" >> /etc/ssh/sshd_config && \
    echo "HostKeyAlgorithms +ssh-rsa,ssh-dss" >> /etc/ssh/sshd_config && \
    echo "Ciphers +aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc" >> /etc/ssh/sshd_config && \
    echo "MACs +hmac-sha1,hmac-sha1-96,hmac-md5" >> /etc/ssh/sshd_config

COPY relay.py /relay.py

EXPOSE 8080

CMD sh -c '( cd /etc/ssh && ssh-keygen -A ) && \
    /usr/sbin/sshd -t -f /etc/ssh/sshd_config && \
    /usr/sbin/sshd -f /etc/ssh/sshd_config && \
    python3 /relay.py'
