#
# Makefile.PL for Netscape::History and Netscape::HistoryURL distribution
#
# Filename:	Makefile.PL
# Author:	Neil Bowers
# Created:	25 January 1997
#

use ExtUtils::MakeMaker;


&WriteMakefile(
               NAME          => 'Netscape',
               DISTNAME      => 'Netscape-History',
               VERSION_FROM  => 'Netscape/History.pm',
               dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
              );
 
