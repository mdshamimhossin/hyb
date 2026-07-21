import socket
import threading
import sys

# Cloud Run থেকে আপনার VPS-এ ট্রাফিক ফরওয়ার্ড করার কনফিগারেশন
VPS_IP = "130.94.101.19"
VPS_PORT = 8080

def handle_client(client_socket):
    try:
        # ক্লায়েন্ট থেকে প্রথম রিকোয়েস্ট (HTTP Upgrade payload) রিড করা
        request = client_socket.recv(4096)
        if not request:
            client_socket.close()
            return
        
        # HTTP Custom / Injector এর WebSocket রিকোয়েস্ট হ্যান্ডশেক রেসপন্স
        if b"Upgrade: websocket" in request or b"upgrade: websocket" in request:
            handshake = (
                b"HTTP/1.1 101 Switching Protocols\r\n"
                b"Upgrade: websocket\r\n"
                b"Connection: Upgrade\r\n\r\n"
            )
            client_socket.sendall(handshake)
        else:
            # যদি সাধারণ HTTP রিকোয়েস্ট হয়, তবে সেটিই পাস করে দেওয়া
            pass

        # আপনার মূল VPS সার্ভারের সাথে কানেক্ট করা
        vps_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        vps_socket.connect((VPS_IP, VPS_PORT))
    except Exception as e:
        client_socket.close()
        return

    # টু-ওয়ে (Two-way) ট্রাফিক ফরওয়ার্ডিং লজিক
    def forward(source, destination):
        try:
            while True:
                data = source.recv(4096)
                if not data:
                    break
                destination.sendall(data)
        except:
            pass
        finally:
            source.close()
            destination.close()

    # দুটি আলাদা থ্রেডে ডেটা আদান-প্রদান শুরু
    threading.Thread(target=forward, args=(client_socket, vps_socket), daemon=True).start()
    threading.Thread(target=forward, args=(vps_socket, client_socket), daemon=True).start()

def main():
    # Cloud Run ডিফল্ট $PORT এনভায়রনমেন্ট ভেরিয়েবল লিসেন করবে
    import os
    port = int(os.environ.get("PORT", 8080))
    
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("0.0.0.0", port))
    server.listen(200)
    print(f"Cloud Run Relay started on port {port}...")

    while True:
        try:
            client_sock, _ = server.accept()
            threading.Thread(target=handle_client, args=(client_sock,), daemon=True).start()
        except KeyboardInterrupt:
            break
        except:
            pass

if __name__ == "__main__":
    main()
