# $Id$
#
# PIE - Perl Inference Engine
# (C)2007, Ralph Bolton, Pre-Emptive Limited
# GNU Public License V2 licensed.
# No warranty is expressed or implied. Use of this software is
# entirely at the user's risk. Pre-Emptive or it's employees accept
# no liability for any damage or loss caused by use of this software.
# For more information, please see http://www.pre-emptive.net/gpl2

package Pie::Attribute::Memory;
use strict;

use Pie::Attribute;
use Pie::Sequence;

sub new
{
	my ($class,$name,@args)=@_;
  my $self = {};

  $self->{NAME} = $name;
  $self->{STATE} = PIE_ATTR_UNSET;
  $self->{VALUE} = undef;
  $self->{SEQUENCE} = 0;
  $self->{CONFIDENCE} = 0;
  $self->{DEPENDS} = {};

  bless $self, $class;
  return $self;
}

sub name
{
  my ($self, $name) = @_;
  my $old = $self->{NAME};
  if(defined($name)) {
    $self->{NAME} = $name;
  }
  return $old;
}

sub set
{
  my ($self, $value, $confidence) = @_;

  if(!defined($value)) {
    return 0;
  }

  if(!defined($confidence)) {
    $confidence = 1;
  }

  # Now see if it's changing the value
  if((!defined($self->{VALUE})) || ("$value" ne '' . defined($self->{VALUE}) . '')) {
    # Either setting for the first time, or changing the value
    # Get a new sequence and update ourselves.
    $self->{SEQUENCE} = Pie::Sequence::next();
    $self->{VALUE} = $value;
    $self->{STATE} = PIE_ATTR_EXTERNAL;
    $self->{CONFIDENCE} = $confidence;
  }

  return 1;
}

sub infer
{
  my ($self, $value, $confidence) = @_;
  my $out = $self->set($value, $confidence);
  if($out) {
    # Now say it was inferred, rather than set
    $self->{STATE} = PIE_ATTR_INFERRED;
  }
  return $out;
}

sub unset
{
  my ($self) = @_;
  $self->{STATE} = PIE_ATTR_UNSET;
  $self->{VALUE} = undef;
  $self->{CONFIDENCE} = 0;
  $self->{SEQUENCE} = Pie::Sequence::next();
  $self->{DEPENDS} = {};
  return 1;
}

# value - return the value of the attribute
sub value
{
  my ($self) = @_;
  if($self->{STATE} != PIE_ATTR_UNSET) {
    return $self->{VALUE};
  }
  return undef;
}

sub confidence
{
  my ($self, $new) = @_;
  my $old = $self->{CONFIDENCE};
  if(defined($new)) {
    $self->{CONFIDENCE} = $new;
  }
  return $old;
}

sub isset
{
  my ($self) = @_;
  if($self->{STATE} != PIE_ATTR_UNSET) {
    return 1;
  }
  return 0;
}

sub depends
{
  my ($self, $attribute, $object) = @_;
  if(!defined($attribute)) {
    return 0;
  }
  if(!defined($object)) {
    # Unset this attribute
    delete(${$self->{DEPENDS}}{$attribute});
    # Update sequence, just so that anything that depends
    # on us gets re-evaluated (just in case)
    $self->{SEQUENCE} = Pie::Sequence::next();
    return 1;
  }

  # Okay, set it...
  ${$self->{DEPENDS}}{$attribute} = $object;
  # Update sequence so that things that depend on us get re-checked
  $self->{SEQUENCE} = Pie::Sequence::next();
  return 1;
}

1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:

