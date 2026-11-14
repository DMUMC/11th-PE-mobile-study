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
  const app = await NestFactory.create(VerificationModule, { logger: false });
  await app.init();
  const evidence = [];
  const owner = { 'x-member-id': '1' };
  const other = { 'x-member-id': '2' };
  async function check(method, path, status, body, headers = {}, errorCode) {
    const response = await send(app.getHttpServer(), method, path, body, headers);
    assert.equal(response.status, status, JSON.stringify(response));
    if (errorCode) assert.equal(response.body.code, errorCode);
    evidence.push({ request: { method, path, headers, body }, response });
    console.log(method, path, response.status);
    return response.body;
  }
  try {
    const sample = { email: 'vector@example.com', nickname: 'Vector', password: 'SamplePassword123!' };
    const member = await check('POST', '/members', 201, sample);
    assert.deepEqual(member, { id: 1, email: sample.email, nickname: sample.nickname });
    assert.match(members.rows[0].passwordHash, /^\$2[aby]\$10\$[./A-Za-z0-9]{53}$/);
    await check('POST', '/members', 409, { ...sample, email: 'VECTOR@example.com', nickname: 'Vector2' }, {}, 'DUPLICATE_MEMBER');
    await check('POST', '/members', 409, { ...sample, email: 'another@example.com' }, {}, 'DUPLICATE_MEMBER');
    assert.equal(members.rows.length, 1);
    await check('POST', '/members', 400, { ...sample, email: 'invalid', password: '123' }, {}, 'VALIDATION_ERROR');
    await check('POST', '/members', 201, { ...sample, email: 'other@example.com', nickname: 'Other' });
    assert.deepEqual(await check('GET', '/members/check-email?email=VECTOR%40example.com', 200), { available: false });
    assert.deepEqual(await check('GET', '/members/check-nickname?nickname=NewVector', 200), { available: true });

    const rating = { movieId: 157336, score: 5 };
    const created = await check('POST', '/ratings', 201, rating, owner);
    assert.equal(created.memberId, 1);
    await check('POST', '/ratings', 400, { ...rating, score: 6 }, owner, 'VALIDATION_ERROR');
    await check('POST', '/ratings', 409, rating, owner, 'DUPLICATE_RATING');
    assert.equal(ratings.rows.length, 1);
    assert.deepEqual(await check('GET', '/members/1/ratings', 200), [created]);

    const path = '/ratings/' + created.id;
    await check('PATCH', path, 403, { score: 4 }, other, 'RATING_FORBIDDEN');
    await check('DELETE', path, 403, undefined, other, 'RATING_FORBIDDEN');
    assert.equal(ratings.rows[0].score, 5);
    assert.equal((await check('PATCH', path, 200, { score: 4 }, owner)).score, 4);
    assert.equal(ratings.rows[0].score, 4);
    assert.equal(await check('DELETE', path, 204, undefined, owner), null);
    await check('DELETE', path, 404, undefined, owner, 'RATING_NOT_FOUND');
    await check('PATCH', path, 404, { score: 4 }, owner, 'RATING_NOT_FOUND');
    assert.deepEqual(await check('GET', '/members/1/ratings', 200), []);
    const directory = resolve(__dirname, '../week06-evidence');
    mkdirSync(directory, { recursive: true });
    writeFileSync(resolve(directory, 'requests-responses.json'), JSON.stringify(evidence, null, 2) + '\n');
    console.log(evidence.length + ' HTTP cases passed; fixture repositories + real bcrypt.');
  } finally {
    await app.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
