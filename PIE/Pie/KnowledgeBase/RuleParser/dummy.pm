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
# dummy.pm - a dummy rule parser for PIE
# This module has some basic rules hard-coded into it, so will always
# make a usable knowledgebase. It's obviously not very useful for
# anything other than testing.
#

package Pie::KnowledgeBase::RuleParser::dummy;

use strict;

use Pie::KnowledgeBase;

sub new
{
	my ($class, $kb)=@_;

	my $self={};

	$self->{KB} = $kb;

	bless $self, $class;

	return $self;
}

sub parse
{
	my ($self)=@_;

	my $kb=$self->{KB};

	return 0 if(!defined($kb));

	# Now add a couple of rules, and questions...

	my $r=$kb->new_rule("connection state");
	$r->add_condition("link.state","up");
	$r->add_condition("local.router.state","up");
	$r->add_condition("remote.router.state","up");
	$r->add_action("internet.connection","up");

	$r=$kb->new_rule("Link down");
	$r->add_condition("link.state","down");
	$r->add_action("internet.connection","down");

	$r=$kb->new_rule("local router");
	$r->add_condition("local.router.state","down");
	$r->add_action("internet.connection","down");

	$r=$kb->new_rule("remote router");
	$r->add_condition("remote.router.state","down");
	$r->add_action("internet.connection","down");

	$r=$kb->new_rule("DNS1");
	$r->add_condition("dns1.state","up");
	$r->add_action("dns.service","up");

	$r=$kb->new_rule("DNS2");
	$r->add_condition("dns2.state","up");
	$r->add_action("dns.service","up");

	$r=$kb->new_rule("DNS down");
	$r->add_condition("dns1.state","down");
	$r->add_condition("dns2.state","down");
	$r->add_action("dns.service","down");

	$r=$kb->new_rule("Internet state");
	$r->add_condition("dns.service","up");
	$r->add_condition("internet.connection","up");
	$r->add_action("internet.status", "up");

	$r=$kb->new_rule("Internet state nodns");
	$r->add_condition("dns.service","down");
	#$r->add_condition("internet.connection","up");
	$r->add_action("internet.status", "down");

	$r=$kb->new_rule("Internet state nonet");
	#$r->add_condition("dns.service","up");
	$r->add_condition("internet.connection","down");
	$r->add_action("internet.status", "down");

	$r=$kb->new_question("link.state","What is the state of the Internet Link?");
	$r->add_response("up");
	$r->add_response("down");

	$r=$kb->new_question("local.router.state","What is the state of the local router?");
	$r->add_response("up");
	$r->add_response("down");

	$r=$kb->new_question("remote.router.state","What is the state of the remote router?");
	$r->add_response("up");
	$r->add_response("down");

	$r=$kb->new_question("dns1.state","What is the state of the DNS Server 1?");
	$r->add_response("up");
	$r->add_response("down");

	$r=$kb->new_question("dns2.state","What is the state of the DNS server 2?");
	$r->add_response("up");
	$r->add_response("down");

	return $kb;
}

1;
