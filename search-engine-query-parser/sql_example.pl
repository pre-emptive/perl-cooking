#!/usr/bin/perl -w

# This example imagines you have web content in a database schema
# something like this:
#
# CREATE TABLE data (
#	maintext	varchar(255),
#	title		varchar(255),
#	url		varchar(255),
#	extension	varchar(255),
#	mimetype	varchar(255),
#	size		varchar(255),
#	body		varchar(255),
# );
#
# ...obviously, this isn't realistic, as your text is likely to be bigger
# that 255 characters! However, imagine you have the main indexed text
# in the "maintext" field, and have separated out the document titles
# into the "title" field, the document bodies into "body" etc.
# 

use Preempt::query::parser;

$user_query = '"fly fishing" OR riverside site:www.example.com filetype:pdf';

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

sub make_sql
{
	my ($ref)=@_;

	my $out="SELECT * FROM data WHERE ";
	my $i;
	my $x=$$ref{'words'};
        my $y=$$ref{'ops'};
        my $z=$$ref{'attribs'};
        for ($i=0; $i<=$#$x; $i++)
	{
		if($$z[$i] =~ /ALL/) {
			$out.='maintext LIKE "%' . $$x[$i] . '%" ';
		}
		if($$z[$i] =~ /TITLE/) {
			$out.='title LIKE "%' . $$x[$i] . '%" ';
		}
		if($$z[$i] =~ /SITE/) {
			$out.='url LIKE "http://' . $$x[$i] . '/%" ';
		}
		if($$z[$i] =~ /URL/) {
			$out.='url LIKE "%' . $$x[$i] . '%" ';
		}
		if($$z[$i] =~ /FILEEXT/) {
			$out.='fileext="' . $$x[$i] . '" ';
		}
		if($$z[$i] =~ /MIME/) {
			$out.='mimetype="' . $$x[$i] . '" ';
		}
		if($$z[$i] =~ /BODY/) {
			$out.='body LIKE "%' . $$x[$i] . '%" ';
		}
		if(defined($$y[$i]))
                {
                        my $op=$$y[$i];
                        $op=~tr/a-z/A-Z/;
                        $out.=$op . " ";
                }
	}

	return "$out;";
}


MAIN:
{
	my %results=();
	my $ret=&Preempt::query::parser::parse($user_query,\%results);
	#my $stuff=join(' ', @{$results{'words'}} );
	my $stuff=&say_response(\%results);
	print "Return was $ret, words are: $stuff\n\n";

	my $sql=&make_sql(\%results);
	print "SQL is $sql\n";

}

