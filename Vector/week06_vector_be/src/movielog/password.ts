import { spawn } from 'node:child_process';

export function bcryptPassword(password: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = spawn(
      process.env.HTPASSWD_BIN ?? 'htpasswd',
      ['-niBC', '10', 'movielog'],
      {
        stdio: ['pipe', 'pipe', 'ignore'],
      },
    );
    const fail = () =>
      reject(
        new Error(
          'bcrypt hashing failed. Check the Apache htpasswd installation.',
        ),
      );
    let output = '';
    child.stdout.setEncoding('utf8').on('data', (chunk: string) => {
      output += chunk;
    });
    child.on('error', fail);
    child.stdin.on('error', fail);
    child.on('close', (code) => {
      const hash = output.trim().slice('movielog:'.length);
      if (
        code !== 0 ||
        !output.startsWith('movielog:') ||
        !/^\$2[aby]\$10\$[./A-Za-z0-9]{53}$/.test(hash)
      ) {
        fail();
        return;
      }
      resolve(hash);
    });
    child.stdin.end(password + '\n');
  });
}
