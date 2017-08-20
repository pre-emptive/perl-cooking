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
# Engine.pm - Perl Inference Engine
#
use warnings;
use strict;
package Pie::Engine;

use Pie::Attribute;

sub new
{
	my ($class, $kbobj, %options)=@_;

	return undef if(!defined($kbobj));

	my $self={};

	bless $self, $class;

  my %defaults = (
    'attributes' => 'Memory',
  );

  my $item;
  # Set defaults and options
  foreach $item (keys %defaults) {
    if(defined($options{$item})) {
      $self->{"OPTION_$item"} = $options{$item};
    } else {
      $self->{"OPTION_$item"} = $defaults{$item};
    }
  }

	$self->{KB}=$kbobj;

	my %data=();
	$self->{ATTRIBUTES}=\%data;
	my @list=();
	$self->{RECURSION_ATTRIBUTES}=\@list;

	$self->{CONDITIONS}=();
	$self->{DEPTH}=0;
	$self->{STATUS}="working";
	$self->{STATUS_OBJECT}=undef;
	$self->{ITERATE_ATTRIBUTE}=();
	$self->{ITERATE_ATTRIBUTES_TO_DO}=();

  $self->{MIXED_MODE} = 0;

	return $self;
}

sub mixed_mode
{
  my ($self, $mode) = @_;
  my $old = $self->{MIXED_MODE};
  if(defined($mode)) {
    $self->{MIXED_MODE} = $mode;
  }
  return $old;
}

sub set_attribute
{
	my ($self,$attribute,$value,$confidence)=@_;

	return 0 if((!defined($attribute)) || (!defined($value)) || ($attribute eq ""));

  my $out = 0;

	if(defined(${$self->{ATTRIBUTES}}{$attribute})) {
    $out = ${$self->{ATTRIBUTES}}{$attribute}->set($value, $confidence);
  } else {
    # make a new attribute
    my $attr = Pie::Attribute->new($attribute,$self->{OPTION_type});
    $out = $attr->set($value, $confidence);
    if($out) {
      ${$self->{ATTRIBUTES}}{$attribute} = $attr;
    }
  }
  if($out) {
  	#print "set_attribute: $attribute set to $value\n";
    # If we're mixed mode, then check for anything else we can set
    if($self->{MIXED_MODE}) {
      $self->solve_with_attribute($attribute);
    }
  } else {
    #print "set_attribute: Failed to set $attribute to $value\n";
  }

	return $out;
}

sub check_attribute
{
	my ($self, $attribute)=@_;

	if(defined(${$self->{ATTRIBUTES}}{$attribute}))
	{
		return 1;
	}
	return 0;
}

sub unset_attribute
{
	my ($self, $attribute)=@_;

	delete(${$self->{ATTRIBUTES}}{$attribute});

	return 1;
}

sub get_attribute_old {
	my ($self, $attribute) = @_;
	if(defined(${$self->{ATTRIBUTES}}{$attribute})) {
		return ${$self->{ATTRIBUTES}}{$attribute}->value;
	}
	return undef;
}

sub get_attribute {
  my ($self, $attribute) = @_;
  if(defined(${$self->{ATTRIBUTES}}{$attribute})) {
    return ${$self->{ATTRIBUTES}}{$attribute};
  }
  return undef;
}


sub get_state
{
	my ($self)=@_;

	return $self->{STATUS};
}

sub get_state_object
{
	my ($self)=@_;
	return $self->{STATUS_OBJECT};
}

# forward_chain
# This is a process of looking in the known attributes and the rules. We then
# try to make any new attributes that we can, given what we know. The idea
# is that we might be able to get to the goal that way, or otherwise make
# backward chaining a bit smarter.
# This is a finite-execution process. It can be run at any time, and just stops
# when it can't do any more. It doesn't even know if it's solved anything.
# As a slight optimisation, the caller can optionally ask for solved rules to be
# skipped. This would mean that changes to the known attributes are not taken into
# account.
sub forward_chain
{
	my ($self,$check_solved)=@_;
	$check_solved=1 if(!defined($check_solved));

	# First, get all the rules that we can work with (even if they've
	# already been solved)
	my @rules=$self->{KB}->get_solvable_rules($self->{ATTRIBUTES},$check_solved);

	# Now (re)solve all the rules...
	my $rule;
	while($rule=shift(@rules))
	{
		my $result=$rule->run_rule($self,$self->{ATTRIBUTES});

		# Now sift the results...
		if(defined($result))
		{
			my $key;
			foreach $key (keys %{$result})
			{
				#print "fwd_chain: Solved $key=" . ${$result}{$key} . " with rule " . $rule->{NAME} . "\n";
				${$self->{ATTRIBUTES}}{$key}=${$result}{$key};
			}
			# We've got new attributes - check for any unsolved rules
			# that have now become solvable
			my @temp=$self->{KB}->get_solvable_rules($self->{ATTRIBUTES},0);
			my $temp;
			foreach $temp (@temp)
			{
				# Only add if not in there already!
				push @rules,$temp unless(grep( { $_ eq $temp } @rules));
			}
		}
	}

	return 1;
}

# solve_with_attribute
# Attempts to forward chain from a given attribute, solving as much as
# possible from that point. In other words, if you set an attribute,
# somewhere in the tree, this function will solve for all other attributes
# that depend on this one. This routine stops as soon as it finds a rule
# that can't be solved because it doesn't have enough information.
# Thus, this is a semi-forward chain, doing forward chaining, but not
# comprehensively.
sub solve_with_attribute
{
  my ($self, $attribute) = @_;

  my @rules = $self->{KB}->get_dependent_rules($attribute);
  my $rule;
  while($rule = shift(@rules)) {
    # Now run the rule, see if it did anything, and bail out if
    # it didn't.
    my $result = $rule->run_rule($self);
    # Now look at results. run_rule sets the attribute(s) it
    # works with. We then scan those results to see what else
    # can be done...
    if($result eq 'solved') {
      my $temp;
      foreach $temp ($rule->get_actions()) {
        my @extra_rules = $self->{KB}->get_dependent_rules($temp);
        push @rules, @extra_rules;
      }
    }
  }
}
  

# backward_chain
# This process starts with a goal (provided as an argument). It then determines
# what it needs to know to reach this goal. It then has a look to see if it
# knows this (in known attributes), if not, then it sees if that knowledge can
# be gleaned from other rules. If so, it tries to solve for those attributes
# using those rules. It ends when an attribute needs to be known, but isn't.
# This can then be used as a prompt to ask the caller to provide that attribute.
# The required attribute is placed into $return_ref.
sub oldbackward_chain
{
	my ($self,$goal_attribute,$return_ref)=@_;

	return 0 if((!defined($goal_attribute)) || ($goal_attribute eq "") || (!defined($return_ref)));

	unshift @{$self->{RECURSION_ATTRIBUTES}},$goal_attribute;

	while($#{$self->{RECURSION_ATTRIBUTES}} >= 0)
	{
		my $ret=$self->_bc_recurse($return_ref);
		if($ret == 0)
		{
			#print "back_chain: Returning because $$return_ref required...\n";
			return 0;
		}
	}

}

sub mixed_chain
{
  my ($self, $goal_attribute) = @_;

  $self->forward_chain();
  if($self->check_attribute($goal_attribute)) {
    return 'solved';
  }

  # Now try mixed mode chaining
  $self->{MIXED_MODE} = 1;
  my $ret = $self->back_chain($goal_attribute);
  $self->{MIXED_MODE} = 0;

  return $ret;
}

# Back Chain
# This process starts with a goal attribute. It then tries to solve for
# that attribute. Since the conditions required may require further rules
# and solutions, each path is tried to see what gets solved. If a required
# attribute is not known, it is asked for. This requires that the various
# paths through the rules are evaluated for efficiency. The most efficient
# path is chosen and used for prompts.
sub back_chain
{
	my ($self,$goal_attribute)=@_;

	return 0 if((!defined($goal_attribute)) || ($goal_attribute eq ""));

	# First, get a list of attributes required to solve this goal
	my @rules=$self->{KB}->get_rules_by_action($goal_attribute);

	#print "Got $#rules + 1 rules for goal attribute $goal_attribute\n";

	if($#rules == -1) {
		# This attribute isn't set by a rule, so it must be
		# a "fact" on the end o fthe chain. We need to ask
		# the user for the value of this attribute, and set it.
		#print "Need to ask for value of $goal_attribute\n";
		#if($goal_attribute eq 'dns2.state') {
		#	#$self->set_attribute("dns2.state","down");
		#	$self->set_attribute("dns2.state", "up");
		#} else {
		#	$self->set_attribute($goal_attribute, 'dunno');
		#}
    #my $ret = $self->{KB}->ask_question($goal_attribute);
    my ($ret, $conf) = $self->{KB}->ask_question($goal_attribute);
    if(defined($ret)) {
      # User has responded usefully, so set the attribute
      $self->set_attribute($goal_attribute, $ret, $conf);
      return 'solved';
    } else {
      return 'failed';
    }
	}

	my $rule;

	my %required=();
	my @candidate_rules=();

	# Now, for each rule, figure out how many attributes need to
	# be solved to solve the rule.
	my $i;
	for($i=0; $i<=$#rules; $i++)
	{
		$rule=$rules[$i];
		#print "loop: $i " . $rule->{NAME} . "\n";

		# Run the rule. If it's partially solved, or unknown
		# then see what's required to solve it. If it's solved
		# already then great. If it's unsolvable, then skip it.
		my $outcome = $rules[$i]->run_rule($self);
		if($outcome eq "unsolvable") {
			# Nothing can be done with this rule
			next;
		} elsif($outcome eq "solved") {
			# Nothing else needs to be done for this
			# goal attribute - it's been set.
			return $outcome;
		}

		# Now see what's required to solve it...
		my @conditions=$rule->get_conditions;
		my $cond;
		my $required = 0;
		foreach $cond (@conditions)
		{
			my $count=$self->_count_required_attributes($cond);
			if($count==0)
			{
				# This is a solvable condition!
				# Do what...?
				#print "Rule " . $rule->{NAME} . " solved because requires no attributes\n";
				$required{$i}=$count;
				#push @candiate_rules, {'required' => $count, 'rule' => $rule};
			}
			else
			{
				#print "Got $count required attributes for $cond on rule " . $rule->{NAME} . "\n";
				$required{$i}=$count;
				#push @candiate_rules, {'required' => $count, 'rule' => $rule};
			}
			$required = $required + $count;
		}
		#print "Adding canidate rule " . $rule->{NAME} . " to list with required=$required\n";
		push @candidate_rules, {'required' => $required, 'rule' => $rule};
	}

	# Now step through each candiate rule, trying to solve
	# each one (recursively). That will make us ask the user
	# for things. If user input means a rule can't be solved
	# or an attribute we need can't be set, then we'll move onto
	# alternative rules (which were initially less attractive).
	#print "Candidate rules are:\n";
	#foreach $rule (sort _candiate_sort @candidate_rules) {
	#	print " Rule " . ${$rule}{'rule'}->{NAME} . " requires " . ${$rule}{'required'} . "\n";
	#}
	#print "Now looping through candidate rules...\n";
	foreach $rule (sort _candiate_sort @candidate_rules) {
		#print "Candate Rule " . ${$rule}{'rule'}->{NAME} . " requires " . ${$rule}{'required'} . "\n";
		my @conditions=${$rule}{'rule'}->get_conditions;
		my $cond;
		foreach $cond (@conditions) {
			if($self->check_attribute($cond)) {
				# Already known - no need to do any more
				next;
			}
			#print "** Recursing into attribute $cond for rule " . ${$rule}{'rule'}->{NAME} . "\n";
			my $outcome = $self->back_chain($cond);
			#print "** Finished recursing $cond for rule " . ${$rule}{'rule'}->{NAME} . "\n";
			#print "Outcome of '" . ${$rule}{'rule'}->{NAME} . "' was $outcome\n";
			#return $outcome;
		}
		# Now we've attempted to resolve all the conditions,
		# finally run the rule and return whatever happened.
		my $outcome =  ${$rule}{'rule'}->run_rule($self);
		#print "** Outcome of running rule " . ${$rule}{'rule'}->{NAME} . " was $outcome\n";
		if($outcome eq 'solved') {
			return $outcome;
		}
	}
	return "failed";
}

sub _candiate_sort {
	return ${$a}{'required'} <=> ${$b}{'required'};
}

sub _count_required_attributes
{
	my ($self, $attribute, $seen_ref) = @_;

	if(!defined($seen_ref)) {
		$seen_ref = {};
	}

	#print "Looking at attribute $attribute\n";

	my $count = 0;

	my @rules = $self->{KB}->get_rules_by_action($attribute);
	if($#rules == -1) {
		# No rules, so this is a fact at the end of the chain
		$count ++;
	}
	my $rule;
	foreach $rule (@rules) {
		if($rule->check_rule_solved($self->{ATTRIBUTES})) {
			# Rule already solved. No attributes required
			# for this one.
			next;
		}
		# get the conditions for this rule
		my @conditions=$rule->get_conditions;
		#print "Got $#conditions conditions for rule " . $rule->{NAME} . "\n";

		if($#conditions == -1) {
			# No conditions, so this is a "fact" at the
			# end of the chain
			$count ++;
			next;
		}

		my $cond;
		foreach $cond (@conditions) {
			# Skip any conditions we've seen already
			if(defined($$seen_ref{$cond})) {
				next;
			}
			# Remember we've seen this condition
			$$seen_ref{$cond} = 1;

			# No need to do anything if this condition is already
			# solved.
			next if($self->check_attribute($cond));

			# Now recurse into the condition
			my $sub_count=$self->_count_required_attributes($cond, $seen_ref);
                        $count=$count + $sub_count;
		}
	}
	#print "Returning count $count\n";
	return $count;
}

# Show working explains why a given attribute is set the way it is.
# It returns a list of attribute objects
sub show_working
{
  my ($self, $attribute) = @_;

  my @rules=$self->{KB}->get_rules_by_action($attribute);

  my @reasons = ();
  my $rule;
  foreach $rule (@rules) {
    my @new = $rule->explain($self);
    if($#new >= 0) {
      #my %out = ('rule' => $rule->name, 'reasons' => \@new);
      push @reasons, { 'rule' => $rule->name, 'reasons' => \@new };
      #push @reasons, \%out;
    }
  }  
  return @reasons;
}

1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
