<?php

/**
 * MySQL connection, history table 
 * and data gather settings
 */

//Will be stored as a host name in daily stats
$host_title = "test_host";

$mysql_user = "root";
$mysql_pass = "";
$mysql_host = "localhost";
//$mysql_db = "";

//Where to store historical data
$daily_db = "dailies";
$daily_table = "daily_stats";


// Pause between stats collection, seconds.
$gather_time = 10;

// Number of data collection (3 = uptime, live delta1 and live delta2)
$gather_passes = 3;


?>