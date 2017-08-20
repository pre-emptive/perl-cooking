#!/usr/bin/perl -w

# contextgrep - return a contextualised grep of a text string. Returns chunks
# of 4 words either side of matches found within a text string. The query is
# broken into "words" which are matched individually. If two matches are near
# each other, then they will be shown as four words either side, with what
# ever is required between them (ie. it's clever). It does not favour all
# matches adjacent to each other over the first few single matches though.

package Preempt::contextgrep;
use warnings;
use HTML::Entities;

# --------------------------
sub grep {
  my ($query,$textref,$max_length)=@_;

  my $word;
  my $prev_pointer=-1;
  my $prev_count=0;
  my @previous=();
  my $to_print=0;

  my $total_printed=0;

  $max_length=300 if(!defined($max_length));

  my $result="";

  # Build a regular expression for the forthcoming
  # code/eval tests...
  my $regex=$query;
  # Change any non word, non digit or non space to a ".?"
  # which will match anything in the forthcoming regex...
  $regex=~s/[^\w\d]/ /g;
  $regex=~s/\s+/|/g;

  my $code=eval 'sub {$_[0] =~s/\b($regex)\b/<b>$1<\/b>/io; }';

  foreach $word (split(/\s+/,$$textref)) {
    if($code->($word)) {
      if($to_print==0) {
        my $i=$prev_pointer;
        my $j;
        if($#previous==3) {
          $result.="... ";
          $total_printed++;
        }
        for($j=0; $j<4; $j++) {
          $i++;
          $i=0 if($i>3);
          if(defined($previous[$i])) {
            $previous[$i]=encode_entities($previous[$i]);
            $result.="$previous[$i] ";
            $total_printed++;
          }
        }
        @previous=();
        $prev_pointer=-1;
      }
      # Remember that we need to keep 6 words
      $to_print=6;
    }

    if($to_print>1) {
      # Start outputting the words we need
      $total_printed++;
      $word=encode_entities($word) unless($to_print==6);
      $result.="$word ";
    } else {
      $prev_pointer++;
      $prev_pointer=0 if($prev_pointer>=4);
      $previous[$prev_pointer]=$word;
    }
    $to_print-- if($to_print>0);
    last if(length($result)>$max_length);
  }
  if($result eq "") {
    # We didn't get anything from our clever grep.
    # Instead, just return the first 300 characters
    # from the text.
    $result=sprintf("%." . $max_length . "s...",$$textref);
    $result=encode_entities($result);
  } else {
    # We got something, put a "..." on the end of it because
    # it's not the whole text, so indicate there's more
    $result.="..." if($result ne "");
  }

  return "$result";
}

1;

