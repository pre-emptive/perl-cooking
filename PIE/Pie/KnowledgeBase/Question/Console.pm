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
# Question.pm - A Knowledgebase Question Object
#

package Pie::KnowledgeBase::Question::Console;

sub new
{
	my ($class,$attribute,$text)=@_;

	return undef if((!defined($attribute)) || (!defined($text)) || ($attribute eq "") || ($text eq ""));

	my $self={};

	bless $self, $class;

	$self->{ATTRIBUTE}=$attribute;
	$self->{TEXT}=$text;
	$self->{RESPONSES}=();

	return $self;
}

sub add_response
{
	my ($self,$response)=@_;

	return 0 if((!defined($response)) || ($response eq ""));

	push @{$self->{RESPONSES}}, $response;

	return 1;
}

# Make sure this question is valid (ie. has some responses)
sub check
{
	my ($self)=@_;

	return 0 if($#{$self->{RESPONSES}} == -1);
	return 1;
}

# See if this question is about the specified attribute
sub check_attribute
{
	my ($self,$attribute)=@_;
	return 1 if($self->{ATTRIBUTE} eq $attribute);
	return 0;
}

sub get_text
{
	my ($self)=@_;
	return $self->{TEXT};
}

sub get_responses
{
	my ($self)=@_;
	return @{$self->{RESPONSES}};
}

sub get_attribute
{
	my ($self)=@_;
	return $self->{ATTRIBUTE};
}

sub ask_question
{
	my ($self)=@_;

	my $options;
  my $force_responses = 0;

	if($#{$self->{RESPONSES}} >= 0) {
		$options = '['  . join('/', @{$self->{RESPONSES}}) . ']';
    $force_responses = 1;
	} else {
		$options = '[]';
	}

  while(1) {

  	print "Question: " . $self->{TEXT} . " $options ";
	  my $response = <STDIN>;
    if(!defined($response)) {
      # Pressed CTRL-D
      print "\n";
      next;
    }
	  $response =~ s/(\n|\r)//g;

    my $confidence;

    # See if a confidence was entered
    if($response =~ /:/) {

      # get everything after the colon
      my @parts = split(/:/, $response);
      $response = shift(@parts);
      $confidence = pop(@parts);
      # Confidence can genuinely be undef, but if it's
      # defined, then make something of it.
      if(defined($confidence)) {
        $confidence =~ s/[^\d\.]*//g;
        if($confidence =~ /^\s*$/) {
          $confidence = 0;
        }
      }
    } else {
      # No confidence entered. Assume definite
      # entry, so confidence = 1
      $confidence = 1;
    }

	  my $temp;
	  foreach $temp (@{$self->{RESPONSES}}) {
		  if(lc($response) eq lc($temp)) {
        if(wantarray) {
  			  return ($response,$confidence);
        } else {
          return $response;
        }
		  }
	  }
    if(!$force_responses) {
      last;
    }
  }
  if(wantarray) {
    return (undef, undef);
  } else {
  	return undef;
  }
}

1;
# The following line is for Vim users - please don't delete it.
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
