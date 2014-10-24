CREATE TABLE IF NOT EXISTS query_review (
   checksum     BIGINT UNSIGNED NOT NULL PRIMARY KEY,
   fingerprint  TEXT NOT NULL,
   sample       TEXT NOT NULL,
   first_seen   DATETIME,
   last_seen    DATETIME,
   reviewed_by  VARCHAR(20),
   reviewed_on  DATETIME,
   comments     TEXT
);