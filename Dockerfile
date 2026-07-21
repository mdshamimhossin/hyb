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

# এখানে python3 relay.py সরাসরি ক্লাউড রানের $PORT (8080) এ লিসেন করবে
# এবং আপনার অ্যাপের পাঠানো 'Upgrade: websocket' রিকোয়েস্ট রিসিভ করে লোকাল SSH পোর্টে (22) পাঠিয়ে দিবে।
CMD sh -c '( cd /etc/ssh && ssh-keygen -A ) ; \
    echo "=== sshd config test ===" ; \
    /usr/sbin/sshd -t -f /etc/ssh/sshd_config ; \
    echo "=== starting sshd on local port 22 ===" ; \
    /usr/sbin/sshd -f /etc/ssh/sshd_config ; \
    echo "sshd exit code: $?" ; \
    echo "=== starting python websocket relay on PORT $PORT ===" ; \
    exec python3 /relay.py'
