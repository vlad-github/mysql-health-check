-- CREATE DATABASE astellar;
-- USE astellar;

CREATE TABLE IF NOT EXISTS daily_stats (
  id int(10) unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  st_collect_date date NOT NULL,
  st_collect_host varchar(255),
  st_name varchar(255),
  st_value int(11) DEFAULT NULL,
  st_value_raw varchar(255) NOT NULL DEFAULT '',
  st_added datetime NOT NULL,
  KEY key_collect_host (st_collect_host),
  UNIQUE KEY key_host_date (st_collect_host, st_collect_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
