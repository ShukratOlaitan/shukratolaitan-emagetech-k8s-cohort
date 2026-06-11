import http.server, socketserver, os, datetime

PORT = int(os.environ.get("PORT", 8000))
GREETING = os.environ.get("GREETING", "hello")
NAME = os.environ.get("STUDENT_NAME", "anonymous")

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = f"{GREETING}, {NAME} — {datetime.datetime.utcnow().isoformat()}Z\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(body.encode())
    def log_message(self, fmt, *args):
        print(f"[req] {self.address_string()} {fmt % args}", flush=True)

with socketserver.TCPServer(("", PORT), Handler) as srv:
    print(f"listening on :{PORT}", flush=True)
    srv.serve_forever()
