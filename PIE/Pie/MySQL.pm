# $Id$
#
# PIE - Perl Inference Engine
# (C)2007, Ralph Bolton, Pre-Emptive Limited
# GNU Public License V2 licensed.
# No warranty is expressed or implied. Use of this software is
# entirely at the user's risk. Pre-Emptive or it's employees accept
# no liability for any damage or loss caused by use of this software.
# For more information, please see http://www.pre-emptive.net/gpl2

# This package provides database access to the Pie application. It
# exports a series of functions that other modules may choose to use.
# The main calling program must connect to the database before any
# use of it can be made. Most DB functions are actually provided
# by the DBI module's object methods.

package Pie::MySQL;

use constant PIE_DB_DEBUG => 1;

use DBI;
use Encode;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT);
$VERSION   = sprintf("%s", "Revision: 1.1.1.1" );
@ISA    = qw(Exporter);
@EXPORT = qw(
  pie_db_connect
  pie_db_errstr
  pie_db_query
  pie_db_sqlify
  pie_db_disconnect
  pie_db_handle
  pie_db_read_one
);

$Pie::MySQL::db_handle = undef;
$Pie::MySQL::last_sql = '';

sub pie_db_connect
{
  my ($db, $user, $password) = @_;

  $Pie::MySQL::db_handle = DBI->connect('DBI:mysql:' . $db, $user, $password);

  return $Pie::MySQL::db_handle;
}

sub pie_db_errstr
{
  return DBI::errstr;
}

sub pie_db_query
{
  my ($sql, @args) = @_;

  # First, construct a suitable SQL string from the "sprintf" format string
  # and arguments we have.

  my @matches = ($sql =~ /%./g);

  my $match;
  foreach $match (@matches) {
    my $value = shift(@args);
    $value = &pie_db_sqlify($value) if($match eq '%s');
    # Should this substitution be substr(index) style?
    my $safe = quotemeta($match);
    $sql =~s/$safe/$value/;
  }

  # Keep it for debug purposes
  $Pie::MySQL::last_sql = $sql;

  # Now tell the DB to prepare it
  my $sth = $Pie::MySQL::db_handle->prepare($sql) if(defined($Pie::MySQL::db_handle));

  if(defined($sth)) {
    # Now execute it
    $sth->execute;
  }

  # Return the DB handle so that the caller can use it
  return $sth;
}

sub pie_db_sqlify
{
  my ($sql) = @_;

  $sql=~s/\'/\\'/g;
  $sql=~s/\!/\\!/g;

  # This encode might be wrong - should we be using UTF8?
  $sql=encode('iso-8859-1',$sql);

  return $sql;
}

sub pie_db_disconnect
{
  return $Pie::MySQL::db_handle->disconnect;
}

sub pie_db_handle
{
  return $Pie::MySQL::db_handle;
}

sub pie_db_read_one
{
  my ($sql, @args) = @_;

  my $sth = pie_db_query($sql,@args);

  return $sth->fetchrow_array if(defined($sth));

  return ();
}

1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:

