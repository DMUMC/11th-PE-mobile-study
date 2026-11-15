CREATE TABLE IF NOT EXISTS members (
  id INT NOT NULL AUTO_INCREMENT,
  email VARCHAR(254) NOT NULL,
  nickname VARCHAR(24) NOT NULL,
  password_hash VARCHAR(60) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_members_email (email),
  UNIQUE KEY uq_members_nickname (nickname)
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ratings (
  id INT NOT NULL AUTO_INCREMENT,
  member_id INT NOT NULL,
  movie_id INT NOT NULL,
  score TINYINT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ratings_member_movie (member_id, movie_id),
  CONSTRAINT fk_ratings_member FOREIGN KEY (member_id) REFERENCES members (id) ON DELETE CASCADE,
  CONSTRAINT chk_ratings_score CHECK (score BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
