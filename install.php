<?php
// Run once from CLI only: php install.php owner@example.com +919999999999 "LongRandomPassword"
if (PHP_SAPI !== 'cli') { http_response_code(403); exit("CLI only\n"); }
if ($argc < 4) { exit("Usage: php install.php email phone password\n"); }
$cfgPath=__DIR__.'/config/config.php'; if(!file_exists($cfgPath)) exit("Create config/config.php first.\n");
$c=require $cfgPath; $d=$c['db']; $pdo=new PDO("mysql:host={$d['host']};dbname={$d['name']};charset=utf8mb4",$d['user'],$d['pass'],[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
$email=$argv[1];$phone=$argv[2];$pass=$argv[3];if(strlen($pass)<14)exit("Password must be at least 14 characters.\n");
$q=$pdo->prepare("INSERT INTO users(name,email,phone,password_hash,role,status) VALUES('Platform Owner',?,?,?,'owner','active')");
$q->execute([$email,$phone,password_hash($pass,PASSWORD_DEFAULT)]);
echo "Owner account created. Store the password in a password manager and remove shell history.\n";
