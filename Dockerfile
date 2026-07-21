FROM alpine:latest

# আপনার আগের সমস্ত প্যাকেজ এবং SSH কনফিগারেশন একদম ঠিক রাখা হয়েছে
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

# আপনার মডিফাইড relay.py স্ক্রিপ্টটি রান করা হবে যা সরাসরি VPS (130.94.101.19)-এ ট্রাফিক পাঠাবে
CMD sh -c '( cd /etc/ssh && ssh-keygen -A ) ; \
    /usr/sbin/sshd -f /etc/ssh/sshd_config ; \
    exec python3 /relay.py'
