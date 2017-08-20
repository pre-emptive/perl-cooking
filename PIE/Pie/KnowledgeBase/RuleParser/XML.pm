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
# XML.pm - an XML Knowledge Base Rule parser for PIE
#
# RuleParsers return a populated KnowledgeBase object. They have to implement
# certain methods, such as parse() (which returns the KB object).

package Pie::KnowledgeBase::RuleParser::XML;

use strict;

use XML::Simple;

sub new
{
	my ($class, $kb)=@_;

	my $self={};
  $self->{KB} = $kb;

	bless $self, $class;

	return $self;
}

sub _clean
{
  my ($text) = @_;

  chomp($text);
  $text =~ s/^\s*//;
  $text =~ s/\s*$//;

  return $text;
}

sub parse
{
	my ($self, @files)=@_;

  my $kb = $self->{KB};
  return 0 if(!defined($kb));

  my $file;
  foreach $file (@files) {

  	if(!-f $file) {
	  	# Not a file, so we can't proceed.
		  print STDERR "File $file was not found\n";
      next;
	  }

    my $simple = XML::Simple->new('ForceArray' => 1, 'KeepRoot' => 0, 'KeyAttr' => []);
    my $data = $simple->XMLin($file);

    my $ref = ${$data}{'pieknowledgebase'};

    # Get relevent XML data...
    my $piedata;
    foreach $piedata (@$ref) {
  
      # Now step through looking for each type of element
      my $rule_ref = ${$piedata}{'rule'};
      my $question_ref = ${$piedata}{'question'};

      my $item;
      if(defined($rule_ref)) {
        foreach $item (@$rule_ref) {
          #my $r = $kb->new_rule($item);
          my $name = ${$item}{'name'};
          my $conditions = ${$item}{'condition'};
          my $actions = ${$item}{'action'};
          if(defined($name) && defined($conditions) && defined($actions)) {
            $name = _clean($name);
            my $r = $kb->new_rule($name);
            my $temp;
            foreach $temp (@$conditions) {
              chomp(${$temp}{'content'});
              $r->add_condition(${$temp}{'attribute'},${$temp}{'content'});
            }
            foreach $temp (@$actions) {
              chomp(${$temp}{'content'});
              $r->add_action(${$temp}{'attribute'}, ${$temp}{'content'});
            } 
          }           
        }
      }

      if(defined($question_ref)) {
        foreach $item (@$question_ref) {
          my $name = ${$item}{'content'};
          my $attr = ${$item}{'attribute'};
          my $responses = ${$item}{'response'};
          if(defined($name) && defined($attr)) {
            $name = _clean($name);
            my $q = $kb->new_question($attr, $name);
            if(defined($responses)) {
              my $temp;
              foreach $temp (@$responses) {
                $q->add_response($temp);
              }
            }
          }
        }
      }
    } # each piedata
  } # foreach file

	return 1;
}

1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
