#!/usr/bin/env python3
"""Sirve build/web con no-cache en index/bootstrap (evita web vieja en túneles)."""
from __future__ import annotations

import argparse
import os
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self) -> None:
        path = self.path.split("?", 1)[0]
        if path in ("", "/", "/index.html") or path.endswith(
            (".html", ".js", ".json", "flutter_bootstrap.js", "flutter_service_worker.js")
        ):
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.send_header("Pragma", "no-cache")
            self.send_header("Expires", "0")
        super().end_headers()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8088)
    parser.add_argument(
        "--directory",
        default="build/web",
        help="Carpeta del build Flutter web",
    )
    args = parser.parse_args()
    os.chdir(args.directory)
    server = ThreadingHTTPServer(("0.0.0.0", args.port), NoCacheHandler)
    print(f"Serving {os.getcwd()} on http://0.0.0.0:{args.port} (no-cache HTML/JS)")
    server.serve_forever()


if __name__ == "__main__":
    main()
