import asyncio
import os

BACKEND_HOST = "127.0.0.1"
BACKEND_PORT = 22
LISTEN_PORT = int(os.environ.get("PORT", 8080))


async def pipe(reader, writer):
    try:
        while True:
            data = await reader.read(4096)
            if not data:
                break
            writer.write(data)
            await writer.drain()
    except Exception:
        pass
    finally:
        writer.close()


async def handle_client(client_reader, client_writer):
    try:
        # Read the initial HTTP request headers (until blank line)
        header_data = b""
        while b"\r\n\r\n" not in header_data and len(header_data) < 8192:
            chunk = await client_reader.read(1)
            if not chunk:
                client_writer.close()
                return
            header_data += chunk

        # We don't validate Sec-WebSocket-Key/Version here on purpose -
        # many mobile SSH tunnel clients send a minimal custom payload
        # that only includes "Upgrade: websocket". As long as that
        # header is present, we accept and switch to raw relay mode.
        if b"upgrade" in header_data.lower() and b"websocket" in header_data.lower():
            response = (
                b"HTTP/1.1 101 Switching Protocols\r\n"
                b"Upgrade: websocket\r\n"
                b"Connection: Upgrade\r\n"
                b"\r\n"
            )
            client_writer.write(response)
            await client_writer.drain()
        else:
            client_writer.write(b"HTTP/1.1 400 Bad Request\r\n\r\n")
            await client_writer.drain()
            client_writer.close()
            return

        # Connect to the real SSH backend
        backend_reader, backend_writer = await asyncio.open_connection(
            BACKEND_HOST, BACKEND_PORT
        )

        await asyncio.gather(
            pipe(client_reader, backend_writer),
            pipe(backend_reader, client_writer),
        )
    except Exception as e:
        print(f"Connection error: {e}")
    finally:
        client_writer.close()


async def main():
    server = await asyncio.start_server(handle_client, "0.0.0.0", LISTEN_PORT)
    print(f"Relay listening on 0.0.0.0:{LISTEN_PORT} -> {BACKEND_HOST}:{BACKEND_PORT}")
    async with server:
        await server.serve_forever()


if __name__ == "__main__":
    asyncio.run(main())
