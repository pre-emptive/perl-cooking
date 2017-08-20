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
# KnowledgeBase.pm - A Knowledge Base object for PIE
#

package Pie::KnowledgeBase;

use strict;

# Callers can optionally name the KnowledgeBase.
sub new
{
	my ($class,%options)=@_;
	my $self={};

  my $item;
  my %defaults = (
    'kb_type' => 'Memory',
    'name' => '',
  );
  foreach $item (keys %defaults) {
    if(defined($options{$item})) {
      $self->{"OPTION_$item"} = $options{$item};
    } else {
      $self->{"OPTION_$item"} = $defaults{$item};
    }
  }

  eval("use Pie::KnowledgeBase::" . $self->{OPTION_kb_type} . ";");
  if($@) {
    print "use Pie::KnowledgeBase::Question::" . $self->{OPTION_kb_type} . " said: $@\n";
    return undef;
  }

  my $obj;
  eval("\$obj = new Pie::KnowledgeBase::" . $self->{OPTION_kb_type} . "(\%options);");
  if($@) {
    print "new Pie::KnowledgeBase::" . $self->{OPTION_kb_type} . " said: $@\n";
    return undef;
  }

  $self->{SUB} = $obj;

	bless $self, $class;
	return $self;
}

sub parse_rules
{
  my ($self, @args) = @_;
  return $self->{SUB}->parse_rules(@args);
}

sub new_rule
{
	my ($self,@args)=@_;
	return $self->{SUB}->new_rule(@args);
}

sub new_question
{
	my ($self,@args)=@_;
	return $self->{SUB}->new_question(@args);
}

sub ask_question
{
  my ($self,@args)=@_;
  return $self->{SUB}->ask_question(@args);
}

sub check_question
{
  my ($self,@args)=@_;
  return $self->{SUB}->check_question(@args);
}

sub get_rules_by_action
{
	my ($self,$attribute)=@_;

	return undef if((!defined($attribute)) || ($attribute eq ""));

  $self->{SUB}->reset_rule_iterator;
	my @rules=();
  my $rule;
  while(1) {
    $rule = $self->{SUB}->iterate_rules;
	  last if(!defined($rule));

		push @rules, $rule if($rule->check_action_attribute($attribute));
	}

	return @rules;
}

sub reset_rule_iterator
{
  my ($self,$args) = @_;
  return $self->{SUB}->reset_rule_iterator($args);
}

sub iterate_rules
{
  my ($self,@args) = @_;
  return $self->{SUB}->iterate_rules(@args);
}

sub reset_question_iterator
{
  my ($self,$args) = @_;
  return $self->{SUB}->reset_question_iterator($args);
}

sub iterate_questions
{
  my ($self,@args) = @_;
  return $self->{SUB}->iterate_questions(@args);
}

# get_solvable_rules
# This looks at all rules and the known attributes. It builds a list
# of rules that can be solved at this point. Of course, this may mean
# more rules can be solved, but this method needs to be called again
# to do that. The caller can optionally ask for solved rules to be
# returned. This allows for re-evaluation, but since it can lead to
# and awful lot of rule running, it can be turned off.
sub get_solvable_rules
{
	my ($self,$data_ref,$provide_solved)=@_;
	$provide_solved=1 if(!defined($provide_solved));
	my @rules_out=();

  $self->{SUB}->reset_rule_iterator;
	my $rule;
  while(1) {
    $rule = $self->{SUB}->iterate_rules;
    last if(!defined($rule));

		# See if the rule can be solved with known attributes...
		my @conditions=$rule->get_conditions;
		my $solvable=1;
		my $temp;
		foreach $temp (@conditions)
		{
			if(!defined(${$data_ref}{$temp}))
			{
				# This attribute not defined, so rule cannot be solved
				$solvable=0;
				last;
			}
		}
		if($solvable)
		{
			if($provide_solved)
			{
				# We're supposed to provide solved rules, so always add this
				# rule
				push @rules_out,$rule;
			}
			else
			{
				# See if this rule has already been solved. If so, don't return
				# it.
				push @rules_out,$rule unless($rule->check_rule_solved($data_ref));
			}
		}
	}

	return (@rules_out);
}

# get_dependent_rules
# Returns a list of rule objects that have conditions that include the
# provided attribute. That is, hand this function an attribute, and it'll
# hand you a list of rule objects that depend on that attribute.
sub get_dependent_rules
{
	my ($self,$attribute) = @_;

  my @out = ();

  $self->{SUB}->reset_rule_iterator;
  my $rule;
  while(1) {
    $rule = $self->{SUB}->iterate_rules;
    last if(!defined($rule));
    my @conditions = $rule->get_conditions;
    my $temp;
    foreach $temp (@conditions) {
      if("$temp" eq "$attribute") {
        # Matched rule against condition
        push @out, $rule;
      }
    }
  }

  return @out;
}

sub check_kb
{
  my ($self) = @_;

  my @errors=();

  # Step through each rule. Look at it's conditions and make sure
  # that they can all be set either by a rule, or by a question.
  my $rule;
  my $iterator1 = 0;
  while(1) {
    $rule = $self->iterate_rules(\$iterator1);
    last if(!defined($rule));

    # Get the rule's conditions
    my @conditions = $rule->get_conditions;
    my $cond;
    foreach $cond (@conditions) {
      # Check each condition of this rule. See if there's a question
      # that sets it, if not, then see if there's another rule that has this
      # attribute as one of it's actions.
      if(!$self->check_question($cond)) {
        # No question associated with this attribute, so check the rules
        my $iterator2 = 0;
        my $found = 0;
        while(!$found) {
          my $scan = $self->iterate_rules(\$iterator2);
          last if(!defined($scan));
          if($scan->check_action_attribute($cond)) {
            # Found it - this condition is good
            $found = 1;
            last;
          }
        }
        if(!$found) {
          # This rule uses attributes not set anywhere. This is an error
          push @errors, 'Rule "' . $rule->name . '" uses attribute "' . $cond . '" which is not set in any rules or questions';
        }
      } # if check_question
    } # foreach condition
  } # while

  # Now step through each question, making sure it sets a used attribute
  # (unused questions don't matter, but may indicate typos and the like)
  $self->reset_question_iterator;
  while(1) {
    my $question = $self->iterate_questions;
    last if(!defined($question));
    # Now step through each rule, looking for a condition with the same attribute
    my $attr = $question->get_attribute;
    $self->reset_rule_iterator;
    my $found = 0;
    while(!$found) {
      $rule = $self->iterate_rules;
      last if(!defined($rule));
      my @conditions = $rule->get_conditions;
      if(grep( {"$_" eq "$attr"} @conditions)) {
        # Found it
        $found = 1;
        last;
      }
    }
    if(!$found) {
      push @errors, 'Question "' . $question->get_text . '" sets attribute "' . $attr . '" which is not used in any rules';
    }
  }

  return @errors;
}

1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
