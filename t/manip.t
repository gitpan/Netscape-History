#!./perl
#
# manip.t - test manipulation routines
#

use Netscape::History;
use DB_File;

use constant FILENAME        => 'history.db';
use constant TESTURL         => 'http://www.perl.com/';
use constant TEST_FIRST_TIME => time();
use constant TEST_LAST_TIME  => (TEST_FIRST_TIME + 10);
use constant TEST_TITLE      => 'perl home page';
use constant TEST_COUNT      => 3;
use constant TEST_EXPIRE     => 2;

print "1..14\n";

my $history;
my $url;
my %hash;

if (-f FILENAME)
{
    unlink FILENAME || die "failed to remove existing file ", FILENAME, "\n";
}


#-----------------------------------------------------------------------
# TEST: 1
# create a valid, but empty, history DB
#-----------------------------------------------------------------------
tie %hash, 'DB_File', FILENAME;
untie %hash;
$history = new Netscape::History FILENAME;
print defined $history ? "ok 1\n" : "not ok 1\n";

#-----------------------------------------------------------------------
# TEST: 2
# Rewind the database
#-----------------------------------------------------------------------
print $history->rewind() ? "ok 2\n" : "not ok 2\n";

#-----------------------------------------------------------------------
# TEST: 3
# Get the next URL, this should be undef, since there are none in there.
#-----------------------------------------------------------------------
$url = $history->next_url();
if (not defined $url)
{
    print "ok 3\n";
}
else
{
    print "not ok 3\n";
}

#-----------------------------------------------------------------------
# TEST: 4
# Add a URL. We just add a static URL.
#-----------------------------------------------------------------------
print $history->add_url(TESTURL) ? "ok 4\n" : "not ok 4\n";

#-----------------------------------------------------------------------
# TEST: 5
# Rewind the database again
#-----------------------------------------------------------------------
print $history->rewind() ? "ok 5\n" : "not ok 5\n";

#-----------------------------------------------------------------------
# TEST: 6
# Get the next URL. This should be the one we just added.
#-----------------------------------------------------------------------
$url = $history->next_url();
if ((not defined $url)
    || ($url ne TESTURL))
{
    print "not ok 6\n";
}
else
{
    print "ok 6\n";
}

#-----------------------------------------------------------------------
# TEST: 7
# The following fields should have the value given
#       COUNT     1
#       EXPIRE    1
#       TITLE     ''
#-----------------------------------------------------------------------
if ($url->visit_count != 1
    || $url->expire != 1
    || $url->title ne '')
{
    print "not ok 7\n";
}
else
{
    print "ok 7\n";
}

#-----------------------------------------------------------------------
# TEST: 8
# Delete the URL from the history. Rewind, get next url.
# There shouldn't be any in there, so we expect to get back undef.
#-----------------------------------------------------------------------
$history->delete_url(TESTURL);
$history->rewind();
$url = $history->next_url();
if (not defined $url)
{
    print "ok 8\n";
}
else
{
    print "not ok 8\n";
}

#-----------------------------------------------------------------------
# TEST: 9
# Manually create our own HistoryURL
#-----------------------------------------------------------------------
$url = new Netscape::HistoryURL(TESTURL,
                                TEST_LAST_TIME,
                                TEST_FIRST_TIME,
                                TEST_COUNT,
                                TEST_EXPIRE,
                                TEST_TITLE);
if (defined $url)
{
    print "ok 9\n";
}
else
{
    print "not ok 9\n";
}
                               
#-----------------------------------------------------------------------
# TEST: 10
# Check that methods return the values we specified on creation
#-----------------------------------------------------------------------
if (defined $url
    && $url->first_visit_time == TEST_FIRST_TIME
    && $url->last_visit_time == TEST_LAST_TIME
    && $url->visit_count == TEST_COUNT
    && $url->expire == TEST_EXPIRE
    && $url->title eq TEST_TITLE)
{
    print "ok 10\n";
}
else
{
    print "not ok 10\n";
}

#-----------------------------------------------------------------------
# TEST: 11
# Add this URL to the database
#-----------------------------------------------------------------------
if ($history->add_url($url))
{
    print "ok 11\n";
}
else
{
    print "not ok 11\n";
}

#-----------------------------------------------------------------------
# TEST: 12
# Rewind history, get next URL, and check it's the same.
#-----------------------------------------------------------------------
$history->rewind();
$url = $history->next_url();
if (defined $url
    && $url->first_visit_time == TEST_FIRST_TIME
    &&  $url->last_visit_time == TEST_LAST_TIME
    &&      $url->visit_count == TEST_COUNT
    &&           $url->expire == TEST_EXPIRE
    &&            $url->title eq TEST_TITLE)
{
    print "ok 12\n";
}
else
{
    print "not ok 12 ($url)\n";
}

#-----------------------------------------------------------------------
# TEST: 13
# Get the next URL. Since there should only be one URL in there,
# we expect to get back NULL.
#-----------------------------------------------------------------------
$url = $history->next_url();
if (not defined $url)
{
    print "ok 13\n";
}
else
{
    print "not ok 13\n";
}

#-----------------------------------------------------------------------
# TEST: 14
# Delete the URL from the history. Rewind, get next url.
# There shouldn't be any in there, so we expect to get back undef.
#-----------------------------------------------------------------------
$history->delete_url(TESTURL);
$history->rewind();
$url = $history->next_url();
if (not defined $url)
{
    print "ok 14\n";
}
else
{
    print "not ok 14\n";
}

unlink FILENAME;

exit 0;
