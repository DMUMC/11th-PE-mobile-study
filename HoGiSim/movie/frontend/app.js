const $ = (id) => document.getElementById(id);
const base = () => {
  const value = $('api-base').value.trim().replace(/\/$/, '');
  const url = new URL(value);
  if (
    !['http:', 'https:'].includes(url.protocol) ||
    url.username ||
    url.password
  ) {
    throw new Error('http 또는 https API 주소를 입력해 주세요.');
  }
  return value;
};

async function callApi(name, path, buttonId) {
  const status = $(name + '-status');
  const button = $(buttonId);
  button.disabled = true;
  status.className = 'status';
  status.textContent = '조회 중이에요…';
  try {
    const url = base() + path;
    $(name + '-url').textContent = 'GET ' + url;
    const response = await fetch(url, {
      headers: { Accept: 'application/json' },
    });
    const data = await response.json();
    $(name + '-json').textContent = JSON.stringify(data, null, 2);
    status.className = 'status ' + (response.ok ? 'ok' : 'error');
    if (!response.ok) {
      status.textContent =
        response.status +
        ' · ' +
        (Array.isArray(data.message) ? data.message.join(' / ') : data.message);
      return null;
    }
    return { data, status };
  } catch (error) {
    status.className = 'status error';
    status.textContent =
      '연결 실패 · 서버 실행 상태와 CORS 허용 출처를 확인해 주세요.';
    $(name + '-json').textContent =
      '브라우저에서 응답을 읽지 못했습니다. Console의 연결/CORS 오류를 확인하세요.';
    console.error('[MovieLog API 연결 실패]', error.message);
    return null;
  } finally {
    button.disabled = false;
  }
}

async function checkNickname(event) {
  event?.preventDefault();
  const result = await callApi(
    'nickname',
    '/members/nickname/' + encodeURIComponent($('nickname').value),
    'nickname-check',
  );
  if (result)
    result.status.textContent =
      '200 OK · ' +
      (result.data.available
        ? '사용할 수 있는 닉네임이에요.'
        : '이미 사용 중인 닉네임이에요.');
}
async function checkEmail(event) {
  event?.preventDefault();
  const result = await callApi(
    'email',
    '/members/email/' + encodeURIComponent($('email').value),
    'email-check',
  );
  if (result)
    result.status.textContent =
      '200 OK · ' +
      (result.data.available
        ? '사용할 수 있는 이메일이에요.'
        : '이미 사용 중인 이메일이에요.');
}
async function getRatings(event) {
  event?.preventDefault();
  const query = new URLSearchParams();
  if ($('page').value !== '') query.set('page', $('page').value);
  if ($('size').value !== '') query.set('size', $('size').value);
  const result = await callApi(
    'ratings',
    '/members/' +
      encodeURIComponent($('member-id').value) +
      '/ratings' +
      (query.size ? '?' + query : ''),
    'ratings-check',
  );
  if (!result) return;
  const rows = result.data;
  result.status.textContent =
    '200 OK · ' +
    (rows.length
      ? '최신 등록순으로 평점을 불러왔어요.'
      : '해당 페이지에 남긴 평점이 없어요.');
  $('rating-count').textContent = rows.length + '개의 기록';
  const list = $('rating-list');
  list.replaceChildren();
  if (!rows.length) {
    const empty = document.createElement('p');
    empty.className = 'empty';
    empty.textContent = '아직 남긴 평점이 없어요.';
    list.append(empty);
    return;
  }
  for (const row of rows) {
    const article = document.createElement('article');
    article.className = 'rating';
    const head = document.createElement('div');
    head.className = 'rating-head';
    const title = document.createElement('h3');
    title.textContent = 'TMDB 영화 #' + row.movieId;
    const stars = document.createElement('span');
    stars.className = 'stars';
    stars.textContent = '★'.repeat(row.score) + ' ' + row.score + '/5';
    head.append(title, stars);
    const comment = document.createElement('p');
    comment.textContent = row.comment ?? '코멘트 없이 남긴 평점이에요.';
    const meta = document.createElement('small');
    meta.textContent =
      '평점 #' +
      row.ratingId +
      ' · ' +
      new Date(row.createdAt).toLocaleString('ko-KR', {
        timeZone: 'Asia/Seoul',
      });
    article.append(head, comment, meta);
    list.append(article);
  }
}
$('nickname-form').addEventListener('submit', checkNickname);
$('email-form').addEventListener('submit', checkEmail);
$('ratings-form').addEventListener('submit', getRatings);
$('check-all').addEventListener('click', async () => {
  const button = $('check-all');
  button.disabled = true;
  try {
    await Promise.all([checkNickname(), checkEmail(), getRatings()]);
  } finally {
    button.disabled = false;
  }
});
