import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';

const files = {
  '/': ['index.html', 'text/html; charset=utf-8'],
  '/index.html': ['index.html', 'text/html; charset=utf-8'],
  '/style.css': ['style.css', 'text/css; charset=utf-8'],
  '/app.js': ['app.js', 'text/javascript; charset=utf-8'],
};
const port = Number(process.argv[2] ?? 5173);
createServer(async (request, response) => {
  const path = new URL(request.url ?? '/', 'http://localhost').pathname;
  const file = files[path];
  if (!file) {
    response.writeHead(404).end('Not Found');
    return;
  }
  try {
    const content = await readFile(
      new URL('../frontend/' + file[0], import.meta.url),
    );
    response
      .writeHead(200, { 'Content-Type': file[1], 'Cache-Control': 'no-store' })
      .end(content);
  } catch {
    response.writeHead(500).end('Frontend file unavailable');
  }
}).listen(port, '127.0.0.1', () =>
  console.log('MovieLog 화면: http://localhost:' + port),
);
