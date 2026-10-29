-- 회원가입/로그인 기능이 없는 5주차 전용 더미 값입니다. 실제 비밀번호가 아닙니다.
INSERT INTO member (email, password, nickname)
SELECT 'noco@umc.com', '$2a$10$dummyEncodedPasswordValue', '수현'
WHERE NOT EXISTS (SELECT 1 FROM member WHERE email = 'noco@umc.com');
INSERT INTO member (email, password, nickname)
SELECT 'minseo@umc.com', '$2a$10$dummyEncodedPasswordValue', '민서'
WHERE NOT EXISTS (SELECT 1 FROM member WHERE email = 'minseo@umc.com');
INSERT INTO member (email, password, nickname)
SELECT 'empty@umc.com', '$2a$10$dummyEncodedPasswordValue', '영화새내기'
WHERE NOT EXISTS (SELECT 1 FROM member WHERE email = 'empty@umc.com');
INSERT INTO rating (member_id, movie_id, score, comment)
SELECT m.member_id, 550, 5, '최고의 영화!' FROM member m
WHERE m.email = 'noco@umc.com' AND NOT EXISTS (
  SELECT 1 FROM rating r WHERE r.member_id = m.member_id AND r.movie_id = 550);
INSERT INTO rating (member_id, movie_id, score, comment)
SELECT m.member_id, 155, 4, '다시 봐도 명작' FROM member m
WHERE m.email = 'noco@umc.com' AND NOT EXISTS (
  SELECT 1 FROM rating r WHERE r.member_id = m.member_id AND r.movie_id = 155);
INSERT INTO rating (member_id, movie_id, score, comment)
SELECT m.member_id, 550, 3, '호불호가 갈릴 것 같아요' FROM member m
WHERE m.email = 'minseo@umc.com' AND NOT EXISTS (
  SELECT 1 FROM rating r WHERE r.member_id = m.member_id AND r.movie_id = 550);
