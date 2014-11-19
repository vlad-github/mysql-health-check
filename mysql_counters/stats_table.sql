-- Copyright (c) 2009-2014 Vladimir Fedorkov (http://astellar.com/)
-- All rights reserved.                                                         
--                                                                              
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
-- OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
-- LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
-- OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
-- SUCH DAMAGE.

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
