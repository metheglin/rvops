#!/usr/bin/perl

$grants = {
  'smb_user' => {
    'databases' => ['smartbeans'],
    'tables' => ['*'],
    'db_clients' => ['localhost'],
    'password' => 'rv_smb',
    'operations' => ['all'],
  },
  'reivo_user' => {
    'databases' => ['reivo'],
    'tables' => ['*'],
    'db_clients' => ['localhost', '172.31.0.1'],
    'password' => 'rv_reivo',
    'operations' => ['select', 'update', 'insert'],
  },
};

