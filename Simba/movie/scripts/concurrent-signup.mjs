// 동시 요청으로 "사전 중복 체크 통과 → DB UNIQUE 위반" 경로를 재현하는 스크립트.
//
// 실행: 서버를 켠 뒤 (npm run start:dev)
//   node scripts/concurrent-signup.mjs            # 회원가입 동시 요청 (기본 10개)
//   node scripts/concurrent-signup.mjs rating 1   # 1번 회원이 같은 영화에 평점 동시 요청
//
// 같은 요청을 동시에 보내면 여러 요청이 exists() 체크를 "아직 없음"으로 통과한 뒤 INSERT에서 충돌한다.
// 회원가입은 체크와 INSERT 사이에 bcrypt 해시(수십 ms)가 있어서 거의 매번 재현된다.
// 결과: 201은 1개, 나머지는 모두 같은 실패 형식의 409여야 한다(500이 섞이면 실패).
// 서버 로그의 "DB UNIQUE 제약 위반(...)을 ...로 변환했습니다." 줄 수가 DB 제약에서 걸러진 요청 수다.

const BASE_URL = process.env.BASE_URL ?? 'http://localhost:3000';
const COUNT = Number(process.env.COUNT ?? 10);
const [mode = 'member', memberId = '1'] = process.argv.slice(2);

const suffix = Date.now().toString(36);

function buildRequest() {
  if (mode === 'rating') {
    return {
      url: `${BASE_URL}/members/${memberId}/ratings`,
      body: { movieId: 900000 + Math.floor(Math.random() * 99999), score: 4 },
    };
  }
  return {
    url: `${BASE_URL}/members`,
    body: {
      email: `race_${suffix}@umc.com`,
      nickname: `race${suffix}`.slice(0, 12),
      password: 'Race1234!',
    },
  };
}

// 모든 요청이 같은 본문을 쓰도록 한 번만 만든다.
const { url, body } = buildRequest();
console.log(`POST ${url} x ${COUNT}`, body);

const results = await Promise.all(
  Array.from({ length: COUNT }, async () => {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const json = await res.json();
    return `${res.status} ${json.code}`;
  }),
);

const summary = results.reduce((acc, key) => {
  acc[key] = (acc[key] ?? 0) + 1;
  return acc;
}, {});
console.table(summary);

const created = results.filter((r) => r.startsWith('201')).length;
const conflicts = results.filter((r) => r.startsWith('409')).length;
const ok = created === 1 && conflicts === COUNT - 1;
console.log(ok ? 'OK: 201 1건, 나머지 409' : 'FAIL: 기대와 다른 응답이 있습니다.');
process.exit(ok ? 0 : 1);
