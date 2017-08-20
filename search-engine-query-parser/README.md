# perl-search-engine-query-parser
An example query parser for Perl based search engines

##Introduction

Attached are various files that might be useful if you're working with search engines. Perl is a great language for textual manipulation. Whilst it's quite a complex routine, the query parser can look at the sorts of searches you might type into a search engine and return machine usable data constructs.

This might all sounds a little complicated. Well, it is. Doing basic searches on some sort of data are quite easy. Doing a simple textual "grep" on some data requires almost no search term parsing. However, what if your data can be searched in complex ways (like if it's stored in a SQL database)? Handling all possible search types and formats gets pretty difficult.

As an example, programatically handling the following searches, perhaps to build an SQL query, gets progressively more difficult:

* fly fishing
* "fly fishing"
* fly AND fishing
* fly AND fishing OR angling
* fly fishing NOT trout
* "fly fishing" +holiday -france

These alone are complicated enough, but handling searches in certain places in your data gets even more complicated. For example:

* intitle:"fly fishing"
* "fly fishing" filetype:pdf
* site:http://support.example.com troubleshooting

The attached query parser actually handles all of these possibilities (and a few more).
##Preempt::query::parser

The package contains a single function called "parse". This function takes two basic arguments (more on the others later). The first is the search query (like any of those above). The second is a reference to a hash. The function parses the query and puts various results into the hash, and returns the number of actual search terms. The number of search terms is the number of words in the query, not including booleans (AND, OR and NOT) or any of the "search limiters" (e.g. site: filetype: etc).

The number of words is also reduced by any redundant terms. For example, a user asking for "one AND two" actually doesn't need to specify the "and". Similarly, asking for "NOT france" makes "not" redundant.

The results are placed into the hash referenced when calling the function. This hash is populated with various entries, which include:
```
$hash{'words'}
$hash{'ops'}
$hash{'attribs'}
```

The above are all references to lists. The words list contains just the plain words of the query. The "ops" list contains the boolean operators between the words (even if none were supplied in the query). The "attribs" list contains result attributes that are required. The attributes indicate what sort of search the word it relates to should be. For example, an attribute of "ALL" indicates all normal fields should be searched, whereas an attribute of "FILEEXT" suggests to only search files of a particular type.

As an example, if the query was for:

"fly fishing" OR riverside angling site:www.example.com filetype:pdf

...then the following would be returned as lists:
```
words = fly fishing, riverside, angling, www.example.com, pdf
ops = OR, AND, AND, AND
attribs = ALL, ALL,  ALL, SITE, FILEEXT
```

Thus, with some clever traversal of the various arrays, it is possible to construct a suitable query for the database in use.

A test case is also provided (parser_query.pl) which demonstrates the inputs and some of the outputs of the query parser function.
Advanced Stuff: Using Stop Words and Synonyms

The parser is able to remove "stop words" from search terms, as well as to insert any "synonyms". These modifications are performed using callback routines.

Example uses for these facilities are in removing common words from searches to improve efficiency or reduce load on a database. Common stop words are "in", "the", "am" and so on.

Synonyms are useful for directing searches to similar things. For example, you may consider "laptop" and "notebook" to the equivalent words, so searching for either one can return suitable results (under the covers, the search would be for "laptop OR notebook", even though the user may have only asked for "laptop").

The test case (parser_query.pl) demonstrates a simple use of callbacks to perform both stop words and synonyms.
##Using the Parser in the Real World

An example of real use of the parser is also provided (sql_example.pl). It generates SQL queries from the search terms provided. It's intended to be an example, and so not fully functional, or perhaps even suitable for many real-world database schemas, but it demonstrates how database search queries can be created from queries parsed with this function.

Lastly, some user-facing documentation of the search terms they would be able to use with this parser is also attached (in HTML format).
