#!/usr/local/bin/perl -w

# $Id$
#
# PIE - Perl Inference Engine
# (C)2007, Ralph Bolton, Pre-Emptive Limited
# GNU Public License V2 licensed.
# No warranty is expressed or implied. Use of this software is
# entirely at the user's risk. Pre-Emptive or it's employees accept
# no liability for any damage or loss caused by use of this software.
# For more information, please see http://www.pre-emptive.net/gpl2

use Pie::KnowledgeBase;
use Pie::Engine;
use Pie::KnowledgeBase::Dumper;
use Pie::MySQL;
use Pie::Sequence;

MAIN:
{
  # For database driven applications, we have to connect to the database
  # before we do anything else. We also tell the internal sequence number
  # generator to use the database.
  my $dbh = pie_db_connect('pie', 'ralph', 'ralphrocks');
  Pie::Sequence::set_type('MySQL');

  # First, create a Knowledge Base. This is basically the body of human
  # knowledge the application will use. It's usually stored on disk as
  # and XML file, although there are ways to store it in a database, for
  # example.
  my $kb = Pie::KnowledgeBase->new();
  $kb->parse_rules('rules.xml');

  # Dumper is optional. It just displays the contents of the Knowledge Base.
  # It's useful while developing rules, but not much use beyond that.
  #Pie::KnowledgeBase::Dumper::dump($kb);

  # Now make an inference engine object. This is the algorithmic part that
  # moves around rules and attributes and works out new things. It needs
  # to know about the rules in the Knowledge Base. For DB attribute
  # storage, we specify the "attributes => MySQL" option.
	my $engine=new Pie::Engine($kbi, {'attributes' => 'MySQL'});

  # Now we start doing the actual inference.
	my $return;
	my $goal = 'internet.status';

  # "mixed mode" is a hybrid forward/backward chaining method. It basically
  # sets the engine into a "just solve it" mode. Neither forward nor backward
  # chaining alone actually solve all possibilities.
	$engine->mixed_mode(1);
	my $ret=$engine->back_chain($goal);
	if($ret eq "solved")
	{
		print "Value of $goal is " . $engine->get_attribute($goal)->value . "\n";
	}
	else
	{
		print "Goal $goal is " . $ret . "\n";
	}
  # Expert Systems can "show their working" and explain why a given outcome
  # is the way it is. The engine can show it's working for a given attribute.
  # It will basically reveal the attributes that helped it arrive at a
  # conclusion. It's not done here, but recursing through the attributes
  # that it says are important will actually show the entire "tree" of
  # decisions that the engine made to arrive at it's final conclusion.
	my @working = $engine->show_working($goal);
	my $work;
	foreach $work (@working) {
    my $ref = ${$work}{'reasons'};
    my @reasons = ();
    my $reason;
    foreach $reason (@$ref) {
      push @reasons, $reason->name . '=' . $reason->value . "(" . $reason->confidence . ")";
    }
    $reason = join(' and ', @reasons);
    print " Because the rule '" . ${$work}{'rule'} . "' found $reason\n";
  }

	print "All done.\n";
}

# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:

