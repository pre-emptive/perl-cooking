# $Id$
#
# PIE - Perl Inference Engine
# (C)2007, Ralph Bolton, Pre-Emptive Limited
# GNU Public License V2 licensed.
# No warranty is expressed or implied. Use of this software is
# entirely at the user's risk. Pre-Emptive or it's employees accept
# no liability for any damage or loss caused by use of this software.
# For more information, please see http://www.pre-emptive.net/gpl2

# Attribute
# Holds an attribute used by the KB. An attribute can be stored in a
# variety of ways, predominantly being memory, DBMs or SQL databases.
# Attributes have a plethora of states, exported from here. Subclasses
# do the actual work, this class is really just a front-man.
#
# Attributes are basically key value pairs. They also can maintain a
# confidence value for the value. When attributes change their state,
# they set a "sequence" number. This gives an indication of the
# freshness of the value.

package Pie::Attribute;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT);
$VERSION   = sprintf("%s", "Revision: 1.1.1.1" );
@ISA    = qw(Exporter);
@EXPORT = qw(
  PIE_ATTR_UNSET
	PIE_ATTR_EXTERNAL
	PIE_ATTR_INFERRED
);
use constant PIE_ATTR_UNSET => 1;
use constant PIE_ATTR_EXTERNAL => 2;
use constant PIE_ATTR_INFERRED => 3;

# new - constructor
# Pass it an attribute name, a "type" and any other arguments required.
# The type can be used to control how the attribute object is implemented.
# The default is to store it in memory, although database storage is also
# possible.
sub new
{
	my ($class,$name,$type,@args)=@_;
  my $self={};

	if((!defined($type)) || ($type eq '')) {
		$type='Memory';
	}

  my $obj;
  eval("use Pie::Attribute::$type; \$obj=Pie::Attribute::$type->new(\$name, \@args)");
  if($@) {
    print STDERR "Pie::Attribute::$type said: $@\n";
    return undef;
  }

  if(defined($obj)) {
    #my $sub = $obj->new($name,@args);
    $self->{SUB} = $obj;
    $self->{NAME} = $name;
    $self->{TYPE} = $type;
    bless $self, $class;
    return $self;
  }

	return undef;
}

# set
# Set is used to firmly set the value of the attribute. This would normally
# be used when the value has been read from some substantial source, like
# a file or register, the user etc. Also see infer()
sub set
{
  my ($self, @args) = @_;
  return $self->{SUB}->set(@args);
}

# infer
# Infer is used internally to denote that this attribute was not set directly,
# but rather set by rules in the system. This differentiation allows for
# better examination of the outcome of various scenarios.
sub infer
{
  my ($self, @args) = @_;
  return $self->{SUB}->infer(@args);
}

# unset
# Used to unset an attribute without destroying the object.
sub unset
{
  my ($self, @args) = @_;
  return $self->{SUB}->unset(@args);
}

# value
# Returns the current value of the attribute (or undef if it's not set)
sub value
{
  my ($self, @args) = @_;
  return $self->{SUB}->value(@args);
}

# confidence
# Gets the confidence value of the attribute's value
sub confidence
{
  my ($self, @args) = @_;
  return $self->{SUB}->confidence(@args);
}

# isset
# A boolean that returns 1 if the attribute has been set, 0 if not.
sub isset
{
  my ($self, @args) = @_;
  return $self->{SUB}->isset(@args);
}

# depends
# Can be used to directly setup dependencies between attributes.
# Pass it the attribute name and the Attribute object.
# It stores a list of all attributes that depend on us. The idea
# being that if we change value, we can run through all depends
# and update them as required.
sub depends
{
  my ($self, @args) = @_;
  return $self->{SUB}->depends(@args);
}

# name
# Returns the name of the attribute (as set by the constructor). Can also
# be used to change the name of the attribute, although that's not likely
# to be needed.
sub name
{
  my ($self, @args) = @_;
  return $self->{SUB}->name(@args);
}



1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:

