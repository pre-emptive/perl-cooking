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
# RuleParse.pm - Perl Object for Parsing Inferrence Engine Rules
#
# This object uses child objects to do the actual work. The children
# allow "datasources" to be added easily. For example, an XML child
# reads XML files, whilst a Database child reads database tables.
#
# No matter which "datasource" is used, the end result is the same -
# a KnowledgeBase object is created and returned. This can then of
# course be used by PIE to determine what needs to be done.

package Pie::KnowledgeBaseRuleParser;

sub new
{
	my ($class,$kb,$type)=@_;

	my $self={};

	bless $self, $class;

	$self->{TYPE}=undef;
	$self->{KB} = $kb;

	# If we've been constructed with a type, set it up...
	if(defined($type))
	{
		unless($self->set_type($type))
		{
			# We failed to set the type - this is a dud object!
			return undef;
		}
	}

	return $self;
}

# set_type(type)
# Attempt to set the type of "datasource". This attempts to "use"
# a class, and construct it. If that works, then we're all good. If not,
# we fail (probably meaning this object is useless!)
# Children don't need to implement set_type().
sub set_type
{
	my ($self,$type)=@_;

	my $obj;

	$type="Pie::KnowledgeBase::RuleParser::$type";

	eval("require $type");
	if($@) {
		print "Failed to load $type: $@\n";
		return 0;
    	}

	eval("\$obj=new $type;");
	if($@) {
		print "new $type said: $@\n";
		return 0;
	}

	return 0 if(!defined($obj));

	$self->{TYPE}=$obj;

	return 1;
}

# Children must implement a parse() method!
sub parse
{
	my ($self,@attrs)=@_;

	return $self->{TYPE}->parse($self->{KB}, @attrs);
}

1;
