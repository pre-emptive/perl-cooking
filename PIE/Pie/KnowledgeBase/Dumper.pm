# $Id$
#
# PIE - Perl Inference Engine
# (C)2007, Ralph Bolton, Pre-Emptive Limited
# GNU Public License V2 licensed.
# No warranty is expressed or implied. Use of this software is
# entirely at the user's risk. Pre-Emptive or it's employees accept
# no liability for any damage or loss caused by use of this software.
# For more information, please see http://www.pre-emptive.net/gpl2

package Pie::KnowledgeBase::Dumper;

use strict;

sub dump
{
  my ($kb) = @_;

  my $item;

  print "KnowledgeBase Dump Begins:\n";

  $kb->reset_rule_iterator;

  #foreach $item (@{$kb->{SUB}->{RULES}}) {
  while(1) {
    $item = $kb->iterate_rules;
    last if(!defined($item));

    print " Rule '" . $item->name . "':\n";
    my $cond;
    foreach $cond (@{$item->{CONDITIONS}}) {
      print "  Condition: if " . ${$cond}{'attribute'} . " = " . ${$cond}{'value'} . "\n";
    }
    my $act;
    foreach $act (@{$item->{ACTIONS}}) {
      print "  Action: Set " . ${$act}{'attribute'} . " to " . ${$act}{'value'} . "\n";
    }
  }

  print "KnowledgeBase Dump Ends.\n";
}


1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
