#!/usr/bin/perl -w

# Preempt::query::parser - "generic" search query parser
# This module parses query terms handed to it in a string.
#
# Essentially, a "query" value is broken into parts. Each part is
# a quoted series of "words", or otherwise single "words". These "words"
# are any series of characters, separated by spaces (as opposed to English
# words, or any other such abstract concept ;-). Each one is taken
# in turn.
#
# If the word is a boolean (in capitals), AND, OR or NOT, then it is
# used as the "op" between words. If a word is preceeded with a
# +, | or - then that too is used as the op between words (respectively).
# Incidentally, two words separated by a + (eg. the+cat) are treated as
# if they were quoted.
#
# Words can also be attribute selectors. For example, a word "intitle:banana"
# would mean "look for the word banana in the title". Other selectors are
# "site:", "intext:", "filetype:" and "url:". These cause attriutes to be
# defined for the search term (which is stripped of it's attibute selector).
# Booleans prepended to attribute selectors are honoured.
#
# Ultimately, a triplet of lists is created (and returned in a hashref). The
# actual return code of the routine is the number of real search words found.
# "real search words" are those not used in attribute selectors (although
# "intext:" is an exception, and considered a real search word). Thus, if
# a search of "site:www.banana.com" was requested, no actual search need be
# performed because the search terms don't make sense (because they limit
# a search, but don't specify what to search for).
#
# The three lists returned all correspond to each other. The first contains
# actual search terms. The second the boolean operators involved and the
# third any attribute selections (of which there may be more than one).
# The last search term in the list has no boolean associated with it -
# thus, "term1 boolean1 term2" is the way the logic works. All terms
# have (at least) default attribute selectors (of "ALL").
#
# In theory, this routine could parse any kind of search query and for it
# to be used with any search middle or backend. In truth, it's all designed
# for Zap/Zebra, but might not take too much to mangle into other forms if
# needs be.

#
# Usage:
#
# my $user_query = "france NOT paris";
# my %query_result=();
# my $count = Preempt::query::parser::parse($user_query, \%query_result);
# if($count > 0) {
#   print "The search was for " . $query_result{'search_terms_html'} . "\n";
# } else {
#   print "The search terms did not contain any searchable words\n";
# }

package Preempt::query::parser;

use strict;
use warnings;

use HTML::Entities;

use constant DEFAULT_OP => 'and';
use constant DEFAULT_ATTR => 'ALL';

# query = the search query (as provided by the user)
# outputref = a hash reference that will get populated with query information
# stopword_cb = an optional reference to a call back function that determines
#   if words are stopwords or not
sub parse
{
	my ($query,$outputref,$stopword_cb,$synonym_cb)=@_;

	my $key;
	my @words=();
	my @ops=();
	my @attribs=();
	my @search_limiters=();
	my @redundant_terms=();
	my @stopwords=();

	# Break the string into "words" (meaning parts, as opposed to
	# real words). The regex is complex - don't ask me to explain ;-)
	# Know that it returns the correct chunks, in and amongst some
	# undefs. Get rid of the undefs, and it's all good ;-)
	my @matches=($query=~/(\"[^\"]*\")|(\S+)/g);
	my $part;
	my $holding="";
	my $holding_attr="";
	foreach $part (@matches)
	{
		# Skip undefs caused by the regex splitter
		next if(!defined($part));
		# Remove the quotes around parts, if they have them...
		$part=~s/"//g;
		# If a terms is 'worda+wordb' then this should be the same
		# as putting it in double quotes (as opposed to 'worda +wordb',
		# which is different)
		$part=~s/([^\s]+)\+([^\s]+)/$1 $2/g;
		# All terms have default attributes unless we find out otherwise
		my $attr=DEFAULT_ATTR;
		# Okay, see if the part is actually an op...
		if(($part eq "OR") || ($part eq "AND") || ($part eq "NOT"))
		{
			if($part eq "AND")
			{
				push @redundant_terms, $part;
			}
			# It's an op, so not a real search word
			if($holding ne "")
			{
				# Have a word in holding, so add it to the
				# list, with this as the op
				my $lpart=$part;
				$lpart=~tr/A-Z/a-z/;
				push @words, $holding;
				push @ops, $lpart;
				push @attribs, $holding_attr;
				$holding="";
				$holding_attr="";
			}
			else
			{
				# If no word in holding, we actually drop this op.
				# It makes no sense to have "NOT worda wordb" because
				# that means "NOT worda AND wordb". It should be
				# written as "wordb NOT worda" if that's what you want.
				push @redundant_terms, $part;
			}
		}
		else
		{
			# It's not an op per-se, but might be included
			# in the word itself (also works on attribute selectors)
			my $op="";
			if($part=~s/^-//)
			{
				$op="not";
			}
			elsif($part=~s/^\+//)
			{
				$op="and";
			}
			elsif($part=~s/^\|//)
			{
				$op="or";
			}

			# It might also have attibutes attached...
			if($part=~s/^site:(.*)$/$1/i)
			{
				unless($part =~/^\s*$/)
				{
					$attr="SITE";
					push @search_limiters, "site:" . $part;
				}
			}
			elsif($part=~s/^intitle:(.*)$/$1/i)
			{
				$attr="ALL+TITLE";
			}
			elsif($part=~s/^inurl:(.*)$/$1/i)
			{
				$attr="ALL+URL";
			}
			elsif($part=~s/^mimetype:(.*)$/$1/i)
			{
				unless($part =~/^\s*$/)
				{
					$attr="MIME";
					push @search_limiters, "mime:" . $part;
				}
			}
			elsif($part=~s/^filetype:(.*)$/$1/i)
			{
				unless($part =~/^\s*$/)
				{
					$attr="FILEEXT";
					push @search_limiters, "filetype:" . $part;
				}
			}
			elsif($part=~s/^intext:(.*)$/$1/i)
			{
				$attr="ALL+BODY";
			}

			# If we got an empty qualifier, then this isn't actually a
			# search term
			next if($part =~ /^\s*$/);

			# Okay, it might have been an prepended op, or
			# an attriute selector, or perhaps just a plain old
			# search term. If we have one in holding, then stick
			# it on the pile with the op we've just figured out.	
			if($holding ne "")
			{
				# also have a word in holding, so push
				# that onto the list with the default op.
				push @words, $holding;
				$op=DEFAULT_OP if($op eq "");
				push @ops, $op;
				push @attribs, $holding_attr;
			}

			my $do_stopwords=1;
			# Now put our new word into holding...
			# (along with it's corresponding attribute selector)
			# This is now Stop Word aware, by means of an optional callback
			# function.
			if(($do_stopwords) && (defined($stopword_cb)))
			{
				# Callback defined, so use it...
				if(&{$stopword_cb}($part))
				{
					# callback returned true - drop this word
					#print STDERR "Parse: dropping stopword $part (attr=$attr)\n";
					push @stopwords, $part;
					$holding="";
					$holding_attr="";
				}
				else
				{
					# callback returned false - use this word
					$holding=$part;
					$holding_attr=$attr;
				}
			}
			else
			{
				# No callback, so we always accept all words...
				$holding=$part;
				$holding_attr=$attr;
			}
		}
	}
	# Okay, end of the loop. Just make sure we don't have anything
	# in holding. Remember, no "op" required, because this is the
	# last term.
	if($holding ne "")
	{
		push @words, $holding;
		push @attribs, $holding_attr;
	}

	# Now build up the various query info strings...
	my $real_search_terms="";
	my $real_search_terms_html="";		# Encoded entities version
	my $real_search_terms_full="";
	my $real_search_terms_full_html="";
	my $search_terms_stripped="";
	my $search_terms_stripped_html="";
	my $search_terms_full_stripped="";
	my $search_terms_full_stripped_html="";
	my %synonyms_inserted=();
	my %synonyms_inserted_html=();

	my $real_search_terms_count=0;
	my $i=0;
	for($i=0; $i<=$#words; $i++)
	{
		# If the current word has attributes that include
		# SITE or MIME, then this word is a search limiter,
		# otherwise it's a real search term.
		unless(($attribs[$i] =~ /MIME/) || ($attribs[$i] =~ /SITE/) || ($attribs[$i] =~ /FILEEXT/))
		{
			if(defined($synonym_cb))
			{
				my $synonym=&{$synonym_cb}($words[$i]);
				if(defined($synonym))
				{
					# We have a synonym for this word, so we have to
					# slip it in amongst the other words.
					unless(grep(/^$synonym$/i,@words))
					{
						# array, offset, length, list
						my $offset=$i+1;
						$offset=$#words if($offset>$#words);
						splice(@words,$offset,0,($synonym));
						splice(@attribs,$offset,0,('ALL'));
						splice(@ops,$i,0,('or'));
						my $word=$words[$i];
						# Make a note of this insertion, so long as it's not done already...
						unless(grep(/^$word$/i,keys %synonyms_inserted))
						{
							$synonyms_inserted{$word}=$synonym;
							$synonyms_inserted_html{$word}=encode_entities($synonym);
						}
					}
				}
			}
			# Real search term...
			$real_search_terms_count++;
			$real_search_terms.="<b>$words[$i]</b> ";
			$real_search_terms_html.='<b>' . encode_entities($words[$i]) . '</b> ';
			$real_search_terms_full.="<b>$words[$i]</b> ";
			$real_search_terms_full_html.='<b>' . encode_entities($words[$i]) . '</b> ';
			$search_terms_stripped.=$words[$i] . ' ';
			$search_terms_stripped_html.=encode_entities($words[$i]) . ' ';
			$search_terms_full_stripped.=$words[$i] . ' ';
			$search_terms_full_stripped_html.=encode_entities($words[$i]) . ' ';
			if(defined($ops[$i]))
			{
				my $uop=$ops[$i];
				$uop=~tr/a-z/A-Z/;
				$real_search_terms.="$uop " if($uop ne "AND");
				$real_search_terms_full.="$uop ";
				$search_terms_full_stripped.="$uop ";
				$search_terms_full_stripped_html.="$uop ";
			}
		}
	}
	$real_search_terms=~s/\s+$//;
	$real_search_terms_full=~s/\s+$//;
	$search_terms_full_stripped=~s/\s+$//;
	$search_terms_full_stripped_html=~s/\s+$//;

	# uniq the search_limiters and redundant_terms lists...
	my @temp;
	# reuse $holding...
	my @search_limiters_html=();
	foreach $holding (@search_limiters)
	{
		unless(grep(/^$holding$/i,@temp))
		{
			push @temp, $holding;
			push @search_limiters_html, encode_entities($holding);
		}
	}
	@search_limiters=@temp;
	@temp=();
	my @redundant_terms_html=();
	foreach $holding (@redundant_terms)
	{
		unless(grep(/^$holding$/i,@temp))
		{
			push @temp, $holding;
			push @redundant_terms_html,encode_entities($holding);
		}
	}
	@redundant_terms=@temp;

	my @stopwords_html=();
	if(defined($stopword_cb))
	{
		@temp=();
		foreach $holding (@stopwords)
		{
			unless(grep(/^$holding$/i,@temp))
			{
				push @temp, $holding;
				push @stopwords_html,encode_entities($holding);
			}
		}
		@stopwords=@temp;
	}
		
	# Populate the output hash reference
	$$outputref{'words'}=\@words;
	$$outputref{'ops'}=\@ops;
	$$outputref{'attribs'}=\@attribs;
	$$outputref{'limiters'}=\@search_limiters;
	$$outputref{'limiters_html'}=\@search_limiters_html;
	$$outputref{'redundant'}=\@redundant_terms;
	$$outputref{'redundant_html'}=\@redundant_terms_html;
	$$outputref{'stopwords'}=\@stopwords;
	$$outputref{'stopwords_html'}=\@stopwords_html;
	$$outputref{'synonyms'}=\%synonyms_inserted;
	$$outputref{'synonyms_html'}=\%synonyms_inserted_html;
	$$outputref{'search_terms'}=$real_search_terms;
	$$outputref{'search_terms_html'}=$real_search_terms_html;
	$$outputref{'search_terms_full'}=$real_search_terms_full;
	$$outputref{'search_terms_full_html'}=$real_search_terms_full_html;
	$$outputref{'search_terms_stripped'}=$real_search_terms;
	$$outputref{'search_terms_stripped'}=~s/<[^>]*>//g;
	$$outputref{'search_terms_stripped_html'}=$search_terms_stripped_html;
	$$outputref{'search_terms_full_stripped'}=$real_search_terms_full;
	$$outputref{'search_terms_full_stripped'}=~s/<[^>]*>//g;
	$$outputref{'search_terms_full_stripped_html'}=$search_terms_full_stripped_html;

	# Add the terms we dropped from the count so that we perform an empty search
	# and so can report the things we dropped, rather than silently ignoring them
	$real_search_terms_count=$real_search_terms_count + $#redundant_terms + @stopwords + 2;

	return $real_search_terms_count;
}

1;

