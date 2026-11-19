const { randomBytes } = require('node:crypto');
const { AccessTokens, JwtGuard } = require('../dist/movielog/auth.js');
const assert = require('node:assert/strict');
const { mkdirSync, writeFileSync } = require('node:fs');
const { resolve } = require('node:path');
const { Duplex } = require('node:stream');
const { Module } = require('@nestjs/common');
const { NestFactory } = require('@nestjs/core');
const { getRepositoryToken } = require('@nestjs/typeorm');
const { Member } = require('../dist/movielog/member.entity.js');
const { Rating } = require('../dist/movielog/rating.entity.js');
const { MembersService } = require('../dist/movielog/members.service.js');
const { RatingsService } = require('../dist/movielog/ratings.service.js');
const { MovieLogController } = require('../dist/movielog/movielog.controller.js');

function fixtureRepository(isDuplicate) {
  const rows = [];
  const matches = (row, criteria) =>
    Object.entries(criteria).every(([key, value]) => row[key] === value);
  return {
    rows,
    existsBy: async (criteria) => rows.some((row) => matches(row, criteria)),
    findBy: async (criteria) => rows.filter((row) => matches(row, criteria)),
    findOne: async ({ where }) => rows.find((row) => matches(row, where)),
    findOneBy: async (criteria) => rows.find((row) => matches(row, criteria)),
    save: async (value) => {
      if (rows.some((row) => isDuplicate(row, value))) {
        throw { driverError: { code: 'ER_DUP_ENTRY' } };
      }
      const row = { id: rows.length + 1, ...value };
      rows.push(row);
      return row;
    },
    update: async (criteria, value) => {
      const row = rows.find((candidate) => matches(candidate, criteria));
      if (row) Object.assign(row, value);
      return { affected: row ? 1 : 0 };
    },
    delete: async (criteria) => {
      const index = rows.findIndex((row) => matches(row, criteria));
      if (index !== -1) rows.splice(index, 1);
      return { affected: index !== -1 ? 1 : 0 };
    },
  };
}

const members = fixtureRepository((a, b) => a.email === b.email || a.nickname === b.nickname);
const ratings = fixtureRepository((a, b) => a.memberId === b.memberId && a.movieId === b.movieId);

class VerificationModule {}
Module({
  controllers: [MovieLogController],
  providers: [
    MembersService,
    AccessTokens,
    JwtGuard,
    RatingsService,
    { provide: getRepositoryToken(Member), useValue: members },
    { provide: getRepositoryToken(Rating), useValue: ratings },
  ],
})(VerificationModule);

// Feed raw HTTP bytes into Nest's Node HTTP server without binding a local port.
function send(server, method, path, body, headers) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    const socket = new Duplex({
      read() {},
      write(chunk, _encoding, callback) {
        chunks.push(Buffer.from(chunk));
        callback();
      },
      final(callback) {
        const output = Buffer.concat(chunks).toString();
        const boundary = output.indexOf('\r\n\r\n');
        const status = Number(output.split(' ')[1]);
        const content = output.slice(boundary + 4);
        try {
          assert(boundary >= 0 && Number.isInteger(status), output);
          resolve({ status, body: content ? JSON.parse(content) : null });
          callback();
        } catch (error) {
          callback(error);
        }
      },
    });
    socket.on('error', reject);
    const json = body === undefined ? '' : JSON.stringify(body);
    const lines = [method + ' ' + path + ' HTTP/1.1', 'Host: localhost', 'Connection: close'];
    for (const [name, value] of Object.entries(headers)) lines.push(name + ': ' + value);
    if (json) lines.push('Content-Type: application/json', 'Content-Length: ' + Buffer.byteLength(json));
    server.emit('connection', socket);
    socket.push(lines.join('\r\n') + '\r\n\r\n' + json);
  });
}

async function main() {
  process.env.JWT_SECRET = randomBytes(32).toString('hex');
  const app = await NestFactory.create(VerificationModule, { logger: false });
  await app.init();
  const evidence = [];
  async function check(method, path, status, body, token, code) {
    const headers = token ? { Authorization: 'Bearer ' + token } : {};
    const response = await send(app.getHttpServer(), method, path, body, headers);
    assert.equal(response.status, status, JSON.stringify(response));
    if (code) assert.equal(response.body.code, code);
    evidence.push({ request: { method, path, authenticated: Boolean(token), body }, response });
    console.log(method, path, response.status);
    return response.body;
  }

  try {
    const owner = { email: 'owner@example.com', password: 'DemoPassword123!' };
    const other = { email: 'other@example.com', password: 'DemoPassword456!' };
    const member = await check('POST', '/members', 201, { ...owner, nickname: 'Owner' });
    await check('POST', '/members', 201, { ...other, nickname: 'Other' });
    const { accessToken } = await check('POST', '/auth/login', 200, owner);
    assert.equal(typeof accessToken, 'string');
    const { accessToken: otherToken } = await check('POST', '/auth/login', 200, other);
    await check('GET', '/members/me', 401, undefined, undefined, 'UNAUTHORIZED');
    assert.deepEqual(await check('GET', '/members/me', 200, undefined, accessToken), member);
    const rating = await check('POST', '/ratings', 201, { movieId: 550, score: 4 }, accessToken);
    assert.equal(rating.memberId, member.id);
    await check('PATCH', '/ratings/' + rating.id, 403, { score: 2 }, otherToken, 'RATING_FORBIDDEN');
    await check('PATCH', '/ratings/' + rating.id, 200, { score: 5 }, accessToken);
    await check('POST', '/auth/login', 401, { ...owner, password: 'WrongPassword123!' }, undefined, 'UNAUTHORIZED');
    await check('GET', '/members/me', 401, undefined, 'invalid', 'UNAUTHORIZED');
    await check('POST', '/ratings', 400, { movieId: 551, score: 4, memberId: 2 }, accessToken, 'VALIDATION_ERROR');
    await check('DELETE', '/ratings/' + rating.id, 403, undefined, otherToken, 'RATING_FORBIDDEN');
    await check('DELETE', '/ratings/' + rating.id, 204, undefined, accessToken);
    const folder = resolve(__dirname, '../week07-evidence');
    mkdirSync(folder, { recursive: true });
    writeFileSync(resolve(folder, 'requests-responses.json'), JSON.stringify(evidence, null, 2) + '\n');
  } finally {
    await app.close();
    delete process.env.JWT_SECRET;
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
