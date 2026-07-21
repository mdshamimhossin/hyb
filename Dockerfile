FROM alpine:latest

# আপনার আগের সব প্যাকেজের সাথে curl এবং tar যুক্ত করা হয়েছে wstunnel ডাউনলোড করার জন্য
RUN apk update && apk add --no-cache python3 openssh shadow curl tar && \
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

# wstunnel ডাউনলোড এবং ইনস্টলেশন (যা WebSocket ট্রাফিককে SSH-এ রিলে করবে)
RUN curl -L https://github.com | tar -xz \
    && mv wstunnel /usr/local/bin/wstunnel

# আপনার আগের ফাইল কপি
COPY relay.py /relay.py

EXPOSE 8080

# আপনার আগের স্ক্রিপ্ট ঠিক রেখে শুধু শেষে wstunnel-কে ব্যাকএন্ড রিলে হিসেবে যুক্ত করা হয়েছে।
# এটি Cloud Run-এর দেওয়া $PORT-এ লিসেন করবে এবং ব্যাকএন্ডের লোকাল SSH (127.0.0.1:22) এ ট্রাফিক পাঠাবে।
CMD sh -c '( cd /etc/ssh && ssh-keygen -A ) ; \
    echo "=== sshd config test ===" ; \
    /usr/sbin/sshd -t -f /etc/ssh/sshd_config ; \
    echo "=== starting sshd ===" ; \
    /usr/sbin/sshd -f /etc/ssh/sshd_config ; \
    echo "sshd exit code: $?" ; \
    echo "=== starting optional relay ===" ; \
    (python3 /relay.py &) ; \
    echo "=== starting wstunnel WebSocket Relay on PORT $PORT ===" ; \
    exec wstunnel server ws://0.0.0.0:${PORT:-8080} --restrictTo=127.0.0.1:22'
