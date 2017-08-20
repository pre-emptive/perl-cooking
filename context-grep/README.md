#Context Grep with Perl

Performing a pattern match on text in Perl is very easy, thanks to it's excellent provision of Regular Expressions. Indeed, if you've got a list of words, Perl's â€œgrepâ€ function will do that pattern matching very nicely for you.

However, getting a little context on any matches can be difficult. Just even getting a few words either side of a matched word makes understanding the text much easier. Most people have probably seen this sort of thing in search engine results. They include a snippet of text, which has the words you searched for highlighted. If the words you asked for weren't near each other, then you see a few words before and after the words you searched for.

The function below takes two arguments. The first is a string of words to search for. The words can be in any order, and should be separated by spaces. The second argument is a reference to the text to search. The text isn't modified in any way, and since it might be quite large it's passed by reference. The function returns an HTML string, containing the search terms in context (each term is wrapped in bold tags to highlight it).
```
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
```
