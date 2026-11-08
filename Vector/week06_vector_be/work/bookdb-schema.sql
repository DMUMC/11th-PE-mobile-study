-- Prepared only; not executed. No data inserts or existing-table changes.
CREATE DATABASE IF NOT EXISTS bookdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS bookdb.category (
  id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS bookdb.book (
  id INT NOT NULL AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  description VARCHAR(255) NOT NULL,
  isAvailable TINYINT NOT NULL DEFAULT 1,
  category_id INT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_book_category FOREIGN KEY (category_id)
    REFERENCES bookdb.category(id)
) ENGINE=InnoDB;
