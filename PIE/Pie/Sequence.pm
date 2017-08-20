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
# The Sequence package is provided as a way for objects to know how
# "fresh" they are. In theory, a rule can check it see if it's attributes
# are fresher than the current outcome of the rule. If fresher, then rerun
# the rule.
# In practice, rules don't do a great deal more work to run than they do
# to check their attributes, so the majority of the benefit it lost.
#
# The facility remains, and is still used, but don't expect it to make things
# a great deal smoother then they were before.
#
package Pie::Sequence;
use strict;

$Pie::Sequence::handler = 'Memory';
$Pie::Sequence::been_used = 0;

sub next
{
  my $ret;
  if(!$Pie::Sequence::been_used) {
    Pie::Sequence::set_type($Pie::Sequence::handler);
  }
  eval("\$ret = Pie::Sequence::" . $Pie::Sequence::handler . "::next();");
  if($@) {
    print "Pie::Sequence::" . $Pie::Sequence::handler . "::next said: $@\n";
  }
  return $ret;
}

sub set_type
{
  my ($type) = @_;
  if($Pie::Sequence::been_used) {
    warn "Pie::Sequence: Changing Sequence type after it's been used is extremely undesirable!\n";
  }
  $Pie::Sequence::handler = $type;
  eval("use Pie::Sequence::" . $Pie::Sequence::handler . ";");
  if($@) {
    print "use Pie::Sequence::" . $Pie::Sequence::handler. " said: $@\n";
  }
  $Pie::Sequence::handler = $type;
  $Pie::Sequence::been_used = 1;
  return 1;
}

1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:

