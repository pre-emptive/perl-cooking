#!/usr/bin/perl -w

use Preempt::query::parser;

my @simplequeries=("oneword", "two words", "now three words",
		"\"two quoted\"", "\"quoted words\" mixed with others",
		"do or die", "a \"fully mixed\" query with \"lots of quotes\"");

my @mediumqueries=("worda NOT wordb wordc", "worda -wordb wordc", "worda |wordb wordc",
		"NOT worda OR wordb wordc", "worda+wordb wordc", "worda +wordb wordc",
		"\"worda+wordb wordc\"");

my @complexqueries=("banana site:www.flibble.com", "banana inurl:fruit",
		"filetype:pdf sales info", "intext:cows intitle:animals",
		"intext:\"two words\"", "the hills are alive with the sound of music",
		"the rain in spain falls mainly on the plains",
		'fly fishing NOT the OR rod',
		'rain and snow',
		'coffee OR cat',
		'cat on the mat');

my @stopwords=('the', 'on');

my %synonyms=('cat' => 'coffee');

sub stopword_callback
{
	my ($word)=@_;

	if(grep( { "$_" eq "$word"} @stopwords))
	{
		#print "**** Stopword callback: Dropping $word\n";
		return 1;
	}
	return 0;
}

sub synonym_callback
{
	my ($word)=@_;

	if(exists($synonyms{$word}))
	{
		return $synonyms{$word};
	}
	return undef;
}

sub say_response
{
	my ($ref)=@_;

	my $out="";
	my $i;
	my $x=$$ref{'words'};
	my $y=$$ref{'ops'};
	my $z=$$ref{'attribs'};
	for ($i=0; $i<=$#$x; $i++)
	{
		$out.="[" . $$z[$i] . "]" .$$x[$i] . " ";
		if(defined($$y[$i]))
		{
			my $op=$$y[$i];
			$op=~tr/a-z/A-Z/;
			$out.=$op . " ";
		}
	}
	return $out;
}

MAIN:
{
	my $query;
	my %results=();
	foreach $query (@simplequeries)
	{
		print "Simple Query is: $query\n";
		my %params=('q' => $query);

		my $ret=&Preempt::query::parser::parse($query,\%results);
		#my $stuff=join(' ', @{$results{'words'}} );
		my $stuff=&say_response(\%results);
		print "Return was $ret, words are: $stuff\n";
	}
	print "================================\n";
	foreach $query (@mediumqueries)
	{
		print "Medium query is: $query\n";
		my %params=('q' => $query);
		$ret=&Preempt::query::parser::parse($query,\%results);
		#my $stuff=join(' ', @{$results{'words'}} );
		my $stuff=&say_response(\%results);
		print "Return was $ret, words are: $stuff\n";
	}
	print "================================\n";
	foreach $query (@complexqueries)
	{
		print "Complex query is: $query\n";
		my %params=('q' => $query);
		$ret=&Preempt::query::parser::parse($query,\%results,\&stopword_callback,\&synonym_callback);
		my $stuff=&say_response(\%results);
		my $stops=join(' ', @{$results{'stopwords'}});
		print "Return was $ret, words are: $stuff\n";
		print "Stopwords are: $stops\n";
	}

}

