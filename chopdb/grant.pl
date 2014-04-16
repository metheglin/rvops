#/usr/bin/perl

use Data::Dumper;
use File::Basename;
use File::Path;

require './data/grants.pl';

my $grant_format = "grant %s privileges on %s.%s to %s@%s identified by '%s' with grant option;\n";

foreach my $db_user ( keys %$grants ) {
  my $grant = $grants->{$db_user};
  my $password = $grant->{'password'};
  foreach my $database ( @{$grant->{'databases'}} ) {
    foreach my $table ( @{$grant->{'tables'}} ) {
      foreach my $db_client ( @{$grant->{'db_clients'}} ) {
        #print $db_client . "\n";
        my $operations = join(',', @{$grant->{'operations'}});
        printf($grant_format, 
          $operations,
          $database,
          $table,
          $db_user,
          $db_client,
          $password
        );
      }
    }
  }
}

print "flush privileges;\n";
