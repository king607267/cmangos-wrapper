<?php
define('DB_SERVER', getenv("MYSQL_HOST") . ":" . getenv("MYSQL_PORT"));
define('DB_USERNAME', getenv("MYSQL_USER"));
define('DB_PASSWORD', getenv("MYSQL_PASSWORD"));
define('DB_NAME', getenv("CMANGOS_CORE") . 'realmd');

/* Attempt to connect to MySQL database */
$con = mysqli_connect(DB_SERVER, DB_USERNAME, DB_PASSWORD, DB_NAME);
$r_db = getenv("CMANGOS_CORE") . "realmd";
// Character database.
$c_db = getenv("CMANGOS_CORE") . "characters";
$cmangos_core = getenv("CMANGOS_CORE");

//realm host and port and name
$realmip = getenv("REALM_HOST");
$realmport = getenv("REALM_PORT");
$realm_name = getenv("REALM_NAME");

//soap host and port
$soaphost = getenv("SOAP_HOST");
$soapport = getenv("SOAP_PORT");


$expansion = getenv("EXPANSION");

// Check connection
if ($con === false) {
    die("ERROR: Could not connect. " . mysqli_connect_error());
}
?>