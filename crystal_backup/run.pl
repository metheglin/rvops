#!/usr/bin/perl

use Data::Dumper;
use File::Basename;
use File::Path;
use Fcntl;
use constant {
  TMP_PATH => dirname(__FILE__) . '/tmp/',
  EXEC_LOG_PATH => dirname(__FILE__) . '/logs/exec.log',
};
require './define.pl';

my $MYSQLDUMP = '/usr/local/mysql/bin/mysqldump';
my $ZIP = '/usr/bin/zip';
my $RSYNC = '/usr/bin/rsync';

## 
## Initialize
## 
$exec_log_path = EXEC_LOG_PATH;
`touch $exec_log_path`;
sysopen (my $OUT, EXEC_LOG_PATH, O_WRONLY | O_APPEND | O_CREAT) or die "can't make log!";
&logger($OUT, "Crystal Backup Started.\n");

## 
## mysql backup
## 
my $date_str = `date +%Y%m%d`;
chomp($data_str);
$date_str =~ s/^\s*(.*?)\s*$/$1/; # trim

foreach $product ( keys %$mysql_list ) {
  my $p = $mysql_list->{$product};

  ## mysqldump
  my $tmp_file_path = TMP_PATH . $product . '.' . $date_str . '.sql';
  my $mysql_cmd = $MYSQLDUMP .
      ' -u' . $p->{'user'} .
      ' -p' . $p->{'password'} .
      ' -h' . $p->{'host'} .
      ' -P' . $p->{'port'} .
      ' ' . $p->{'database'} .
      ' > ' . $tmp_file_path;
  system($mysql_cmd);
  if ( $? != 0 ) {
    &logger($OUT, "Failed to mysqldump. : $mysql_cmd\n");
    exit(1);
  }
  
  ## zip
  my $tmp_zip_file_path = $tmp_file_path . '.zip';
  my $zip_cmd = "$ZIP -P " . $p->{'zip_password'} . " $tmp_zip_file_path $tmp_file_path";
  system($zip_cmd);
  if ( $? != 0 ) {
    &logger($OUT, "Failed to zip. : $zip_cmd\n");
    exit(1);
  }
  
  ## rsync
  my $fortif = $p->{'fortif'};
  $fortif_path = $fortif->{'path'} . $product . '/';
  my $rsync_cmd = "$RSYNC " . $tmp_zip_file_path .
      ' ' . $fortif->{'user'} . '@' . $fortif->{'host'} . ':' . $fortif_path;
  system($rsync_cmd);
  if ( $? != 0 ) {
    &logger($OUT, "Failed to rsync. : $rsync_cmd\n");
    exit(1);
  }
  
  ## remove
  unlink($tmp_file_path);
  unlink($tmp_zip_file_path);
}

## 
## Defines
## 
sub logger {
  my $out = shift;
  my $msg = shift;
  chomp( my $date = `date '+%Y/%m/%d %H:%M:%S'` );
  print $out "[$date] ". $msg ."\n";
}
