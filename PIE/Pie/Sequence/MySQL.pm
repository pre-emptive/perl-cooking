# $Id$
#
# PIE - Perl Inference Engine
# (C)2007, Ralph Bolton, Pre-Emptive Limited
# GNU Public License V2 licensed.
# No warranty is expressed or implied. Use of this software is
# entirely at the user's risk. Pre-Emptive or it's employees accept
# no liability for any damage or loss caused by use of this software.
# For more information, please see http://www.pre-emptive.net/gpl2
#
package Pie::Sequence::MySQL;
use strict;

use Pie::MySQL;

sub next
{
  my ($name) = @_;
  $name = 'pie_core' if(!defined($name));
  my $sth = pie_db_query("select id from pie_sequences where name='%s'", $name);
 
  my @line = $sth->fetchrow_array;
  if(defined($line[0])) {
    my $id = $line[0] + 1;
    $sth = pie_db_query("replace into pie_sequences values('%s', %d)", $name, $id);

    return $id;
  } else {
    # No sequence started yet, create it
    my $id = 1;
    $sth = pie_db_query("insert into pie_sequences values('%s', %d)", $name, $id);

    return $id;
  } 
}

1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:

