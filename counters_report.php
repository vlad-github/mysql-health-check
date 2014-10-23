<?php

//error_reporting(0);

$host_title = "ET15";

$mysql_user = "root";
$mysql_pass = "myl%_ro4ot_@501";
$mysql_host = "localhost";
$mysql_db = "";

$gather_time = 10;
$gather_passes = 3;

$vars = array();

function get_stats()
{
    global $vars, $gather_passes, $gather_time, $host_title;
    global $mysql_user, $mysql_pass, $mysql_host;
    $stats = array();
	mysql_connect($mysql_host, $mysql_user, $mysql_pass) or die("Can't connect to MySQL, please check connection parameters");
	//mysql_select_db($mysql_db) or die("select_db");
    echo "collecting data for $host_title, passes: ";
	for($i = 0; $i < $gather_passes; $i++)
	{
	    // let counters change
	    if ($i > 0) sleep($gather_time);

	    // gather them
		$r = mysql_query("SHOW GLOBAL STATUS");
		while($a = mysql_fetch_assoc($r))
		{
		    $name = $a["Variable_name"];
		    $value = (int)$a["Value"];
		    //print $name . " | " . (() ? "1" : "0") . " | " . $value . " " . $a["Value"] . "\n";
		    if($a["Value"] == "$value") 
		    {
		        //first value?
		        if(empty($vars[$name])) 
		        {
		        	$vars[$name][] = $stats[$name] = $value;
		        } else {
		        	// make second value relative
		        	$vars[$name][] = $value - $stats[$name];
		        	$stats[$name] = $value;
		        }
		    }
		}
		echo $i + 1 . "/" . $gather_passes . " ";
	}
	status_store_abs($stats, $host_title);
	echo "Done!\n";
}

function db_connect()
{
    global $conn;
    //$conn = new SQLite3('dailies.db') or die("Can't connect to dailies.db");
    //var_dump($conn);
    return $conn;

}

function status_store_abs($stats = array(), $host = "hostname")
{
    global $conn;
    if (empty($conn)) $conn = db_connect();

    foreach($stats as $name => $val)
    {
        //echo "INSERT INTO stats (date, host, name, val) VALUES (date('now'), '$host', '$name', '$val')\n";
        //$conn->exec("INSERT INTO stats (date, host, name, val) VALUES (date('now'), '$host', '$name', '$val')");
    }
}

function relative($stat_name, $pos = 0)
{
    global $vars;
	return ((float)$vars["$stat_name"][$pos])/$vars["Uptime"][$pos];
}

function fancy($stat_name, $pos = 0)
{
    global $vars;
	return number_format(relative($stat_name, $pos));
}

function rw_rate($pos = 0)
{
	return relative("Com_select", $pos) / (relative("Com_update", $pos) + relative("Com_insert", $pos) + relative("Com_delete", $pos));
}

function fancy_rate($pos = 0)
{
	return number_format(rw_rate($pos));
}

function row($stat_name, $max_review_no = 0, $title = "")
{
    global $vars;
    $title = empty($title) ? $stat_name : $title . " rate";
    printf("%1$-40s", $title);
    for ($i = 0; $i <= $max_review_no; $i++ ) print fancy($stat_name, $i) . "\t";
    print "\n";
}

/*
foreach($stats as $dummy => $stat)
{
    $values = explode("|", $stat);
    $title = trim($values[1]);
    //Integer values only by now
    $value = (int)$values[2];
    $vars[$title][] = $value;
}
*/

get_stats();

// ***** REPORT *****

printf("%1$-40s", "Rates:"); print "Uptime\tReview\tReview2\n";
printf("%1$-40s", "Select rate:"); print fancy("Com_select") . "\t" . fancy("Com_select", 1) . "\t" . fancy("Com_select",2).  "\n";
printf("%1$-40s", "Insert rate:"); print fancy("Com_insert") . "\t" . fancy("Com_insert", 1) . "\t" . fancy("Com_insert", 2).  "\n";
printf("%1$-40s", "Update rate:"); print fancy("Com_update") . "\t" . fancy("Com_update", 1) . "\t" . fancy("Com_update", 2).  "\n";
printf("%1$-40s", "Delete rate:"); print fancy("Com_delete") . "\t" . fancy("Com_delete", 1) . "\t" . fancy("Com_delete", 2).  "\n";

printf("%1$-40s", "R/W rate:"); print fancy_rate(0) . "\t" . fancy_rate(1) . "\t" . fancy_rate(2).  "\n";

print "================= IO pressure: ================= \n";
row("Handler_read_rnd", 2);
row("Innodb_data_writes", 2);
row("Innodb_dblwr_writes", 2);
row("Innodb_log_writes", 2);
row("Innodb_pages_written", 2);

//row("Innodb_pages_read", 2);
//row("Innodb_data_reads", 2);

print "================= buffres and pools =================\n";
row("Key_read_requests", 2);
row("Key_reads", 2);

print "================= Selects: =================\n";
row("Select_full_join", 2);
row("Select_scan", 2);
row("Created_tmp_files", 2);
row("Created_tmp_disk_tables", 2);

print "================= Locking: =================\n";
row("Innodb_log_waits", 2);
row("Table_locks_waited", 2);

print "================= Caching: =================\n";
row("Threads_created", 2);
row("Connections", 2);

/*
print "\nQuery cache stats:\n";

print "Hits:\t\t\t"    . number_format($vars["Qcache_hits"][0]) . "\n";
print "Inserts:\t\t" . number_format($vars["Qcache_inserts"][0]) . "\n";
print "Efficiency:\t\t" . number_format((float)$vars["Qcache_hits"][0]/$vars["Com_select"][0], 2) . "\n";

*/

?>
