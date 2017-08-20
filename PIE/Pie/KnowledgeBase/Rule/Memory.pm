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
# Rule.pm - A Knowledgebase Rule Object
#

package Pie::KnowledgeBase::Rule::Memory;

use strict;

sub new
{
	my ($class,$name)=@_;

	return undef if((!defined($name)) || ($name eq ""));

	my $self={};

	bless $self, $class;

	$self->{NAME}=$name;
	$self->{CONDITIONS}=();
	$self->{ACTIONS}=();
  $self->{KNOWN_GOOD} = ();
  $self->{KNOWN_BAD} = ();
	$self->{STATE} = 'unknown';
  $self->{SEQUENCE} = 0;

	return $self;
}

sub name
{
  my ($self) = @_;
  return $self->{NAME};
}

sub add_condition
{
	my ($self,$attribute,$value)=@_;

	return 0 if((!defined($attribute)) || (!defined($value)) || ($attribute eq ""));

	push @{$self->{CONDITIONS}}, { 'attribute' => $attribute, 'value' => $value };

	return 1;
}

sub add_action
{
	my ($self,$attribute,$value)=@_;

	return 0 if((!defined($attribute)) || (!defined($value)) || ($attribute eq ""));

	push @{$self->{ACTIONS}}, { 'attribute' => $attribute, 'value' => $value };
	return 1;
}

# Check - make sure the rule has some conditions and actions
sub check
{
	my ($self)=@_;
	return 0 if(($#{$self->{CONDITIONS}} == -1) || ($#{$self->{ACTIONS}} == -1));
	return 1;
}

# Check if this rule has a particular attribute set in it's action
sub check_action_attribute
{
	my ($self,$attribute)=@_;
	my $action;
	foreach $action (@{$self->{ACTIONS}})
	{
		return 1 if(${$action}{'attribute'} eq $attribute);
	}
	return 0;
}

# Check if rule already solved
sub check_rule_solved
{
	my ($self,$data_ref)=@_;
	my $attr;
	my $is_solved=1;
  my $action;
	foreach $action (@{$self->{ACTIONS}})
	{
		my $attr=${$action}{'attribute'};
		if(!defined(${$data_ref}{$attr}))
		{
			# Not solved
			$is_solved=0;
			last;
		}
	}
	return $is_solved;
}

# get a list of conditions associated with this rule
sub get_conditions
{
	my ($self)=@_;

	my @conditions=();
	my $cond;
	foreach $cond (@{$self->{CONDITIONS}})
	{
		push @conditions, ${$cond}{'attribute'};
	}
	return @conditions;
}

sub get_actions
{
  my ($self) =@_;
	my @actions=();
        my $act;
        foreach $act (@{$self->{ACTIONS}})
        {
                push @actions, ${$act}{'attribute'};
        }
        return @actions;
}

sub explain
{
  my ($self, $engine) =@_;

  my $cond;
  my @out = ();
  if($#{$self->{KNOWN_GOOD}} >= 0 && $#{$self->{KNOWN_BAD}} < 0) {
    foreach $cond (@{$self->{KNOWN_GOOD}}) {
      my $attr = $engine->get_attribute(${$cond}{'attribute'});
      if(defined($attr)) {
        #print "Condition: " . $self->name . " : " . ${$cond}{'attribute'} . " attr=$attr\n";
        if($attr->value eq ${$cond}{'value'}) {
          # This was a reason for the rule firing
          push @out, $attr;
        }
      }
    }
  }
  return @out;
}

# combine_confidences
# Takes a list of confidence values and returns an aggregate of them.
# Eg. A confidence of 1 and 0.5 might result in a confidence of 0.75.
# The algorithm for combination is the subject of some debate.
sub combine_confidences
{
  my ($self, @confidences) = @_;

  my $total = 0;
  my $item;
  my $count = 0;
  foreach $item (@confidences) {
    # Confidence can be undef if it can't be established
    if(defined($item)) {
      # Make sure $item is numeric
      $item = $item + 0;
      $item = 1 if($item > 1);
      $item = 0 if($item < 0);
      $total = $total + $item;
      $count ++;
    }
  }
  if($count) {
    # Return the mean average confidence
    # This may not be the best way to determine overall confidence
    my $out = $total / $count;
    return $out;
  } else {
    return undef;
  }
}

sub run_rule {
	my ($self, $engine) = @_;

	# Look into the rule. The rule may be solvable, solved, unsolvable or
	# partially solved. 

	if($self->{STATE} eq 'solved' || $self->{STATE} eq 'unsolvable') {
		# Already arrived at a conclusion no need to
		# do any more
		return $self->{STATE};
	}

	# To get here, we may be partially solved, or have never
	# attempted to solve it.
	my $known_good = 0;
	my $known_bad = 0;
	my $unknown = 0;
	my $ref;
  $self->{KNOWN_GOOD} = ();
  $self->{KNOWN_BAD} = ();
  my @confidences = ();
	foreach $ref (@{$self->{CONDITIONS}}) {
		my $attr_name = ${$ref}{'attribute'};
		my $rule_value = ${$ref}{'value'};

    my $attr = $engine->get_attribute($attr_name);
    my $value;
    if(defined($attr)) {
      $value = $attr->value;
      push @confidences, $attr->confidence;
    }
		if(defined($value)) {
			if("$value" eq "$rule_value") {
				# This attribute is as required
				$known_good++;
        push @{$self->{KNOWN_GOOD}}, $ref;
			} else {
				# Incorrect value
				$known_bad++;
        push @{$self->{KNOWN_BAD}}, $ref;
			}
		} else {
			# No value known
			$unknown++;
		}
	}

	# Okay, now see what happened.
	if($unknown == 0 && $known_bad == 0) {
		# No bad values, so this rule is solved. Perform
		# it's actions, and return
    my $confidence = $self->combine_confidences(@confidences);
		foreach $ref (@{$self->{ACTIONS}}) {
			$engine->set_attribute(${$ref}{'attribute'}, ${$ref}{'value'}, $confidence);
		}
		$self->{STATE} = 'solved';
    $self->{SEQUENCE} = Pie::Sequence::next();
	} elsif($known_bad != 0) {
		# Nothing unknown, but some values not as required
		# so this rule is unsolvable
		$self->{STATE} = 'unsolvable';
    $self->{SEQUENCE} = Pie::Sequence::next();
	} elsif($unknown != 0 && $known_good != 0) {
		# Some stuff known, but more to find out
		$self->{STATE} = 'partial';
	} else {
		# Something else.
		$self->{STATE} = 'unknown';
	}
	return $self->{STATE};
}

1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
