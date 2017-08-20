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
# This object contains all you need to know for a single Knowledge Base.
# That is, a KB has a Goal, Rules and Questions. This object encapsulates
# all of them in a form that can be used by the actual Engine.
#
# The structure of the information stored in this object is:
#
# KB (hash)
#	Goal -> hash -> [attributes => list, text => scalar]
#	Rules -> listof -> hash [name => scalar, conditions => list, actions => list]
#		conditions -> listof -> hash [attribute => scalar, value => scalar]
#		actions -> listof -> hash [attribute => scalar, value => scalar]
#	Questions -> listof -> hash [attribute => scalar, text => scalar, responses => list]
#		responses -> listof -> scalar

package Pie::KnowledgeBase::Memory;

use strict;

# Callers can optionally name the KnowledgeBase.
sub new
{
	my ($class,%options)=@_;
	my $self={};

  my $item;
  my %defaults = (
    'rule_storage' => 'Memory',
    'question_type' => 'Console',
    'rule_source' => 'XML',
    'name' => '',
  );
  foreach $item (keys %defaults) {
    if(defined($options{$item})) {
      $self->{"OPTION_$item"} = $options{$item};
    } else {
      $self->{"OPTION_$item"} = $defaults{$item};
    }
  }

  eval("use Pie::KnowledgeBase::Question::" . $self->{OPTION_question_type} . ";");
  if($@) {
    print "use Pie::KnowledgeBase::Question::" . $self->{OPTION_question_type} . " said: $@\n";
    return undef;
  }

  eval("use Pie::KnowledgeBase::Rule::" . $self->{OPTION_rule_storage} . ";");
  if($@) {
    print "use Pie::KnowledgeBase::Rule::" . $self->{OPTION_rule_storage} . " said: $@\n";
    return undef;
  }

  eval("use Pie::KnowledgeBase::RuleParser::" . $self->{OPTION_rule_source} . ";");
  if($@) {
    print "use Pie::KnowledgeBase::RuleParser::" . $self->{OPTION_rule_source} . " said: $@\n";
  }

	bless $self, $class;

	$self->{RULES}=();
	$self->{QUESTIONS}={};

  $self->{RULE_ITERATOR} = 0;
  $self->{QUESTION_ITERATOR} = 0;

	return $self;
}

sub parse_rules
{
  my ($self, @args) = @_;
  my $obj;
  eval("\$obj = new Pie::KnowledgeBase::RuleParser::" . $self->{OPTION_rule_source} . "(\$self);");
  if($@) {
    print "new Pie::KnowledgeBase::RuleParser::" . $self->{OPTION_rule_source} . " said: $@\n";
    return undef;
  }
  return $obj->parse(@args);
}

sub new_rule
{
	my ($self,$name)=@_;

  my $rule;
  eval("\$rule = new Pie::KnowledgeBase::Rule::" . $self->{OPTION_rule_storage} . "(\$name);");
  if($@) {
    print "new Pie::KnowledgeBase::Rule::" . $self->{OPTION_rule_storage} . " said: $@\n";
    return undef;
  }

  if(defined($rule)) {
  	push @{$self->{RULES}}, $rule if(defined($rule));
  } else {
    print "Rule not created: $@\n";
  }

	return $rule;
}

sub new_question
{
	my ($self,$attribute,$text)=@_;

  my $question;
  eval("\$question = new Pie::KnowledgeBase::Question::" . $self->{OPTION_question_type} . "(\$attribute, \$text);");
  if($@) {
    print "new Pie::KnowledgeBase::Question::" . $self->{OPTION_question_type} . " said: $@\n";
    return undef;
  }

  if(defined($question)) {
  	${$self->{QUESTIONS}}{$attribute} = $question if(defined($question));
  }

	return $question;
}

sub ask_question
{
  my ($self, $attribute) = @_;
  
  if(exists(${$self->{QUESTIONS}}{$attribute})) {
    return ${$self->{QUESTIONS}}{$attribute}->ask_question();
  }
  return undef;
}

sub check_question
{
  my ($self, $attribute) = @_;

  if(exists(${$self->{QUESTIONS}}{$attribute})) {
    return 1;
  }
  return 0;
}


sub reset_rule_iterator
{
  my ($self) = @_;
  $self->{RULE_ITERATOR} = 0;
  return 1;
}

sub iterate_rules
{
  my ($self, $iterator_ref) = @_;

  my $iterator;
  my $use_external;

  if(defined($iterator_ref) && ref($iterator_ref) eq 'SCALAR') {
    $use_external = 1;
    $iterator = $$iterator_ref + 0;
  } else {
    $iterator = $self->{RULE_ITERATOR};
    $use_external = 0;
  }

  my $out = ${$self->{RULES}}[$iterator];

  if(defined($out)) {
    $iterator++;
    if($use_external) {
      $$iterator_ref = $iterator;
    } else {
      $self->{RULE_ITERATOR} = $iterator;
    }
  }

  return $out;
}

sub reset_question_iterator
{
  my ($self) = @_;
  $self->{QUESTION_ITERATOR} = 0;
  return 1;
}

sub iterate_questions
{
  my ($self, $iterator_ref) = @_;

  my $iterator;
  my $use_external;

  if(defined($iterator_ref) && ref($iterator_ref) eq 'SCALAR') {
    $use_external = 1;
    $iterator = $$iterator_ref + 0;
  } else {
    $iterator = $self->{QUESTION_ITERATOR};
    $use_external = 0;
  }

  my @keys = sort keys %{$self->{QUESTIONS}};

  my $index = $keys[$iterator];

  my $out;

  $out = ${$self->{QUESTIONS}}{$index} if(defined($index));

  if(defined($out)) {
    $iterator++;
    if($use_external) {
      $$iterator_ref = $iterator;
    } else {
      $self->{QUESTION_ITERATOR} = $iterator;
    }
  }

  return $out;
}

1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
