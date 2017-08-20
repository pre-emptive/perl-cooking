#Z3950::grs1 - Convert Strings to and from Unicode and GRS1 character encoding

SYNOPSIS
```
use Z3950::grs1;

$a = "This is \303\242\302\200\302\231 data";
$b = "This is \273 unicode";
grs2uni($a);           # $a now in Unicode
uni2grs($b);           # $b now in grs1
```
DESCRIPTION

NOTE: This is (probably) not a complete implementation of GRS1 to/from Unicode conversions. It's also not the best Perly way to realise the functionality. Your mileage may vary.

This module deals with Z3950 GRS1 format records (specifically those coming out of IndexData's Zebra server, although others are probably the same). GRS1 uses a character encoding unlike UTF-8, ISO8859-1 or other standard encodings. It uses a string of octets that signify certain things. There must be a standard for this, but this module was created through observation and reverse-engineering.

The module provides the following functions:
```
grs2uni($string, [$unsafe_chars])
```
This routine replaces GRS1 formatted characters with their Unicode counterparts. Note: This (probably) requires Perl 5.7 upwards to work. Anything unrecognised is left alone. If a second argument is supplied, only those characters are modified. This hasn't been tested, so may not do quite what you expect.
```
uni2grs($string, [$unsafe_chars])
```
This routine replaces Unicode (or ISO8859-1) characters in $string with their GRS1 counterparts. Unknown characters are left alone. A second argument can be used to specify which characters should be changed. This has not been tested, so may not work as you expect.

Both routines modify the string passed as the first argument if called in a void context. In scalar and array contexts the encoded or decoded string is returned (and the argument string is left unchanged).

If you prefer not to import these routines into your namespace you can call them as:
```
  use Z3950::grs1 ();
  $uni = Z3950::grs1::grs2uni($b);
  $grs = Z3950::grs1::uni2grs($a);
```
The module can also export the %grs2uni and the %uni2grs hashes which contain the mapping from all characters in one format to the other.
COPYRIGHT

Copyright 2004 Ralph Bolton, Pre-Emptive Limited. GPLv2 Licensed.

This library is heavily inspired by HTML::Entities by Gisle Aas. It should probably have been inspired by Encode instead, but it isn't :-( This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
