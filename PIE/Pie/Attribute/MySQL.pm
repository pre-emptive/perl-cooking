# $Id$
#
# PIE - Perl Inference Engine
# (C)2007, Ralph Bolton, Pre-Emptive Limited
# GNU Public License V2 licensed.
# No warranty is expressed or implied. Use of this software is
# entirely at the user's risk. Pre-Emptive or it's employees accept
# no liability for any damage or loss caused by use of this software.
# For more information, please see http://www.pre-emptive.net/gpl2

package Pie::Attribute::MySQL;
use strict;

use Pie::Attribute;
use Pie::Sequence;

use Pie::MySQL;

sub new
{
	my ($class,$name,$preserve,@args)=@_;
  my $self = {};

  # These two are kept in memory because we need to use them to find
  # things in the DB.
  $self->{MYID} = Pie::Sequence::next();

  # If preserve is set and true, then don't clear this
  # attribute from the database.
  if(!defined($preserve) || !$preserve) {
    # See if this attribute has already been set
    my $sth;
    my @line = pie_db_read_one("SELECT id FROM pie_attributes WHERE name='%s'", $name);
    if(defined($line[0])) {
      # There was a previous entry, which needs it's depends entries removing
      $sth = pie_db_query("DELETE FROM pie_dependencies WHERE id=%d", $line[0]);
    }
    # Clear this entry from the DB 
    $sth = pie_db_query("DELETE FROM pie_attributes WHERE name='%s'", $name);

    # Now set the initial values in the DB
    $sth = pie_db_query("INSERT INTO pie_attributes (id, name, state, value, confidence, sequence) VALUES (%d, '%s', %d, NULL, %d, %d)", $self->{MYID}, $name, PIE_ATTR_UNSET, 0, 0);
  }

  bless $self, $class;
  return $self;
}

sub name
{
  my ($self, $name) = @_;
  # First, get the current name...
  my @line = pie_db_read_one("SELECT name FROM pie_attributes WHERE id=%d", $self->{MYID});
  my $old = $line[0];
  if(defined($name)) {
    my $sth = pie_db_query("UPDATE pie_attributes SET (name) VALUES ('%s') WHERE id=%d", $name, $self->{MYID});
  }
  return $old;
}

sub set
{
  my ($self, $value, $confidence, $infer) = @_;

  if(!defined($value)) {
    return 0;
  }

  if(!defined($confidence)) {
    $confidence = 1;
  }

  # Now see if it's changing the value
  if((!defined($self->{VALUE})) || ("$value" ne '' . $self->{VALUE} . '')) {
    # Either setting for the first time, or changing the value
    # Get a new sequence and update ourselves.
    my $sequence = Pie::Sequence::next();
    my $state = PIE_ATTR_EXTERNAL;
    $state = PIE_ATTR_INFERRED if(defined($infer));
    my $sth;
    if(defined($value)) {
      $sth = pie_db_query("UPDATE pie_attributes SET value='%s', state=%d, confidence=%f, sequence=%d WHERE id=%d", $value, $state, $confidence, $sequence, $self->{MYID});
    } else {
      $sth = pie_db_query("UPDATE pie_attributes SET value=NULL, state=%d, confidence=%f, sequence=%d WHERE id=%d", $state, $confidence, $sequence, $self->{MYID});
    }
  }

  return 1;
}

sub infer
{
  my ($self, $value, $confidence) = @_;
  return $self->set($value, $confidence, 1);
}

sub unset
{
  my ($self) = @_;

  my $sequence = Pie::Sequence::next();
  # Remove dependencies
  pie_db_query("DELETE FROM pie_dependencies WHERE id=%d", $self->{MYID});

  my $sth = pie_db_query("UPDATE pie_attributes SET value=NULL, state=%d, confidence=%f, sequence=%d WHERE id=%d", PIE_ATTR_UNSET, 0, $sequence, $self->{MYID});
  return 1;
}

# value - return the value of the attribute
sub value
{
  my ($self, $value) = @_;
  # First, get the current name...
  my @line = pie_db_read_one("SELECT value FROM pie_attributes WHERE id=%d", $self->{MYID});
  my $old = $line[0];
  if(defined($value)) {
    my $sth = pie_db_query("UPDATE pie_attributes SET (value) VALUES ('%s') WHERE id=%d", $value, $self->{MYID});
  }
  return $old;
}

sub confidence
{
  my ($self, $new) = @_;
  # First, get the current name...
  my @line = pie_db_read_one("SELECT confidence FROM pie_attributes WHERE id=%d", $self->{MYID});
  my $old = $line[0];
  if(defined($new)) {
    my $sth = pie_db_query("UPDATE pie_attributes SET (confidence) VALUES ('%s') WHERE id=%d", $new, $self->{MYID});
  }
  return $old;
}

sub isset
{
  my ($self) = @_;
  my @line = pie_db_read_one("SELECT state FROM pie_attributes WHERE id=%d", $self->{MYID});

  if(!defined($line[0]) || $line[0] != PIE_ATTR_UNSET) {
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
  my $sequence = Pie::Sequence::next();
  pie_db_query("UPDATE pie_attributes SET (sequence) VALUES ('%s') WHERE id=%d", $sequence, $self->{MYID});

  if(!defined($object)) {
    # Delete it from the dependencies table...
    pie_db_query("DELETE FROM pie_dependencies WHERE name='%s'", $attribute);
    return 1;
  }

  # Okay, set it, if not already set
  my @line = pie_db_read_one("SELECT name FROM pie_dependencies WHERE name='%s'", $attribute);
  if(!defined($line[0])) {
    # Not already set, so add it
    pie_db_query("INSERT INTO pie_dependencies SET (id, name) VALUES (%d, '%s')", $self->{MYID}, $attribute);
  }

  return 1;
}

1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:

