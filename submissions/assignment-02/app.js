const http = require('http');
const PORT = parseInt(process.env.PORT || '8000', 10);
const GREETING = process.env.GREETING || 'hello';
const NAME = process.env.STUDENT_NAME || 'anonymous';

http.createServer((req, res) => {
  const body = `${GREETING}, ${NAME} — ${new Date().toISOString()}\n`;
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end(body);
  console.log(`[req] ${req.socket.remoteAddress} ${req.method} ${req.url}`);
}).listen(PORT, () => console.log(`listening on :${PORT}`));
