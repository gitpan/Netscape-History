#!./perl
#
# empty.t - tests based around an empty history.db file.

use Netscape::History;
use DB_File;

use constant FILENAME => 'history.db';

print "1..2\n";

my $history;
my %hash;

#-----------------------------------------------------------------------
# TEST: 1
# non-existent file, so we expect to get undef back
# we put in a WARN handler, so the carp from the constructor
# doesn't worry anyone.
#-----------------------------------------------------------------------
{
    local $SIG{__WARN__} = sub { };

    if (-f FILENAME)
    {
	unlink FILENAME || die "failed to remove existing file ",
				FILENAME, "\n";
    }
    $history = new Netscape::History FILENAME;
    print defined $history ? "not ok 1\n" : "ok 1\n";
}

#-----------------------------------------------------------------------
# TEST: 2
# create a valid, but empty, history DB
#-----------------------------------------------------------------------
tie %hash, 'DB_File', FILENAME;
untie %hash;
$history = new Netscape::History FILENAME;
print defined $history ? "ok 2\n" : "not ok 2\n";
$history->close() if defined $history;
unlink FILENAME;

exit 0;
