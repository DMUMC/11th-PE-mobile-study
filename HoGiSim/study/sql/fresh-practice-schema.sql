-- 새 연습용 DB 전용입니다. 3주차 DB에 재실행하지 마세요.
-- Workbench에서 새 스키마를 선택한 뒤 실행합니다.
CREATE TABLE category (
  category_id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL,
  PRIMARY KEY (category_id)
);
CREATE TABLE book (
  book_id INT NOT NULL AUTO_INCREMENT,
  category_id INT NOT NULL,
  title VARCHAR(100) NOT NULL,
  description TEXT NULL,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (book_id),
  CONSTRAINT fk_book_category FOREIGN KEY (category_id) REFERENCES category(category_id)
);
-- 중복 제목 제약은 npm run migration:run으로 추가합니다.
INSERT INTO category (name) VALUES ('프로그래밍'), ('소설');
INSERT INTO book (category_id, title, description, is_available) VALUES
  (1, '스프링 입문', '스프링 기초 학습', TRUE),
  (2, '도서 대여 중 예시', NULL, FALSE);
