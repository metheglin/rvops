#!/usr/bin/perl

$common_zip_pass = 'sanosuke10';
$common_fortif = {
  'user' => 'rvuser', # nopassword ssh required
  'host' => '59.106.191.75', # agile01.reivo.co.jp
  'port' => '22', # ssh port
  'path' => '/home/rvuser/crystal_backup/' # absolute path required
};
$mysql_list = {
  'jeis_production' => {
    'user' => 'jeis_user',
    'password' => 'rv_jeis',
    'host' => 'localhost',
    'port' => '3306',
    'database' => 'jeis_production',
    'zip_password' => $common_zip_pass,
    'fortif' => $common_fortif
  },
  'jeis_front' => {
    'user' => 'jeis_user',
    'password' => 'rv_jeis',
    'host' => 'localhost',
    'port' => '3306',
    'database' => 'jeis_front',
    'zip_password' => $common_zip_pass,
    'fortif' => $common_fortif
  }
}; 
