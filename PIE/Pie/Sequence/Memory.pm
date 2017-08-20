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
package Pie::Sequence::Memory;
use strict;

$Pie::Sequence::Memory::global_counter = 0;

sub next
{
  $Pie::Sequence::Memory::global_counter++;
  return $Pie::Sequence::Memory::global_counter;
}

1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:

