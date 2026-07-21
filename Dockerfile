FROM alpine:latest

# Install required packages
RUN apk update && apk add --no-cache \
    python3 \
    openssh \
    shadow \
    curl \
    tar

# Create user
RUN adduser -D -s /bin/sh alex && \
    echo "alex:alex" | chpasswd

# Prepare sshd
RUN mkdir -p /run/sshd && \
    ssh-keygen -A

# Configure SSH
RUN sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "AllowUsers alex" >> /etc/ssh/sshd_config && \
    echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config && \
    echo "GatewayPorts yes" >> /etc/ssh/sshd_config && \
    echo "PermitTunnel yes" >> /etc/ssh/sshd_config && \
    echo "KexAlgorithms +diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1" >> /etc/ssh/sshd_config && \
    echo "HostKeyAlgorithms +ssh-rsa" >> /etc/ssh/sshd_config && \
    echo "PubkeyAcceptedAlgorithms +ssh-rsa" >> /etc/ssh/sshd_config && \
    echo "Ciphers +aes128-cbc,aes192-cbc,aes256-cbc" >> /etc/ssh/sshd_config && \
    echo "MACs +hmac-sha1" >> /etc/ssh/sshd_config

# Download wstunnel v10.5.5
RUN curl -L \
https://github.com/erebe/wstunnel/releases/download/v10.5.5/wstunnel_10.5.5_linux_amd64.tar.gz \
-o /tmp/wstunnel.tar.gz && \
tar -xzf /tmp/wstunnel.tar.gz -C /usr/local/bin && \
chmod +x /usr/local/bin/wstunnel && \
rm -f /tmp/wstunnel.tar.gz

# Copy relay script
COPY relay.py /relay.py

EXPOSE 8080

CMD sh -c '\
mkdir -p /run/sshd && \
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then ssh-keygen -A; fi && \
echo "=== Testing sshd config ===" && \
/usr/sbin/sshd -t && \
echo "=== Starting sshd ===" && \
/usr/sbin/sshd && \
echo "=== Starting relay.py ===" && \
python3 /relay.py & \
echo "=== Starting wstunnel on port ${PORT:-8080} ===" && \
exec wstunnel server ws://0.0.0.0:${PORT:-8080} --restrict-to 127.0.0.1:22'
