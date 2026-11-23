#!/usr/bin/env python3
"""Relay a local Unix socket to a Rex server on the tailnet.

tailscaled runs in userspace mode on this Mac, so apps can't reach tailnet
addresses directly. This listens on a Unix socket that a Rex host endpoint can
point at, and forwards each connection over HTTPS through tailscaled's
outbound HTTP proxy.
"""

import argparse
import asyncio
import os
import socket
import ssl
import sys


def log(message):
    print(message, file=sys.stderr, flush=True)


def proxy_connect(proxy_host, proxy_port, host, port):
    sock = socket.create_connection((proxy_host, proxy_port), timeout=15)
    try:
        request = f"CONNECT {host}:{port} HTTP/1.1\r\nHost: {host}:{port}\r\n\r\n"
        sock.sendall(request.encode())
        response = b""
        while b"\r\n\r\n" not in response:
            chunk = sock.recv(4096)
            if not chunk:
                raise ConnectionError("proxy closed the connection")
            response += chunk
        status = response.split(b"\r\n", 1)[0].decode(errors="replace")
        if status.split()[1:2] != ["200"]:
            raise ConnectionError(f"proxy refused the connection: {status}")
        sock.settimeout(None)
        return sock
    except BaseException:
        sock.close()
        raise


async def pipe(reader, writer):
    try:
        while data := await reader.read(65536):
            writer.write(data)
            await writer.drain()
    except (ConnectionError, ssl.SSLError):
        pass


async def handle(args, context, client_reader, client_writer):
    loop = asyncio.get_running_loop()
    try:
        sock = await loop.run_in_executor(
            None, proxy_connect, args.proxy_host, args.proxy_port, args.host, args.port
        )
        if context is not None:
            upstream_reader, upstream_writer = await asyncio.open_connection(
                sock=sock, ssl=context, server_hostname=args.host
            )
        else:
            upstream_reader, upstream_writer = await asyncio.open_connection(sock=sock)
    except Exception as error:
        log(f"connecting to {args.host}:{args.port}: {error}")
        client_writer.close()
        return

    tasks = [
        asyncio.ensure_future(pipe(client_reader, upstream_writer)),
        asyncio.ensure_future(pipe(upstream_reader, client_writer)),
    ]
    await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
    for task in tasks:
        task.cancel()
    for writer in (client_writer, upstream_writer):
        writer.close()


async def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--socket", help="Unix socket to listen on")
    parser.add_argument("--tcp", help="loopback HOST:PORT to listen on")
    parser.add_argument("--host", required=True, help="tailnet name of the Rex server")
    parser.add_argument("--port", type=int, default=443)
    parser.add_argument("--no-tls", action="store_true", help="connect to upstream without TLS")
    parser.add_argument("--proxy", default="localhost:1055", help="tailscaled HTTP proxy")
    args = parser.parse_args()
    args.proxy_host, _, proxy_port = args.proxy.rpartition(":")
    args.proxy_port = int(proxy_port)
    if not args.socket and not args.tcp:
        parser.error("give --socket, --tcp, or both")

    context = None if args.no_tls else ssl.create_default_context()
    servers = []

    if args.socket:
        directory = os.path.dirname(args.socket)
        os.makedirs(directory, mode=0o700, exist_ok=True)
        os.chmod(directory, 0o700)
        if os.path.exists(args.socket):
            os.unlink(args.socket)
        os.umask(0o177)
        servers.append(
            await asyncio.start_unix_server(
                lambda r, w: handle(args, context, r, w), path=args.socket
            )
        )
        log(f"relaying {args.socket} to {args.host}:{args.port} via {args.proxy}")

    if args.tcp:
        tcp_host, _, tcp_port = args.tcp.rpartition(":")
        servers.append(
            await asyncio.start_server(
                lambda r, w: handle(args, context, r, w), host=tcp_host, port=int(tcp_port)
            )
        )
        log(f"relaying {args.tcp} to {args.host}:{args.port} via {args.proxy}")

    await asyncio.gather(*(server.serve_forever() for server in servers))


if __name__ == "__main__":
    asyncio.run(main())
