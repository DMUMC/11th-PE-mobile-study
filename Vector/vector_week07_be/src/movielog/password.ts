import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
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

export async function verifyPassword(password: string, hash: string) {
  const directory = await mkdtemp(join(tmpdir(), 'movielog-bcrypt-'));
  const file = join(directory, 'credentials');
  try {
    await writeFile(file, 'movielog:' + hash + '\n', { mode: 0o600 });
    return await new Promise<boolean>((resolve, reject) => {
      const child = spawn(
        process.env.HTPASSWD_BIN ?? 'htpasswd',
        ['-vi', file, 'movielog'],
        { stdio: ['pipe', 'ignore', 'ignore'] },
      );
      child.on('error', reject);
      child.stdin.on('error', reject);
      child.on('close', (code) => {
        if (code === 0 || code === 3) resolve(code === 0);
        else reject(new Error('htpasswd could not verify the password.'));
      });
      child.stdin.end(password + '\n');
    });
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}
