#-----------------------------------------------------------------------

=head1 NAME

Netscape::History - object class for accessing Netscape history database

=head1 SYNOPSIS

    use Netscape::History;
    
    $history = new Netscape::History();
    while (defined($url = $history->next_url() ))
    {
    }

=cut

#-----------------------------------------------------------------------

package Netscape::History;
require 5.004;
use strict;

#-----------------------------------------------------------------------

=head1 DESCRIPTION

The C<Netscape::History> module implements an object class for
accessing the history database maintained by the Netscape web browser.
The history database keeps a list of all URLs you have visited,
and is used by Netscape to change the color of URLs which you have
previously visited, for example.

With this module, you can get at the URLs stored in a Netscape history
file, delete URLs, and add new ones. With the associated
C<Netscape::HistoryURL> module you can access the information which
is associated with each URL.

B<Please Note:> the database format for the browser history was changed
with Netscape 4. Previously only the time of most recent visit was
available; now you can also get at the time of your first visit,
the number of visits, the title of the referenced page, and another value.

=head2 PLEASE NOTE

In version 2.00 of this module, you had to set the
C<$Netscape::History::NETSCAPE_VERSION> variable
to the major version number of the Netscape you were using,
since there was a change in the information stored for each URL
between versions 3 and 4.
In a subsequent version we removed the need for the variable,
thanks to a suggestion from Jimmy Aitken.

Previously, setting the variable would silently do nothing,
from this version onwards it will result in an error.

=cut

#-----------------------------------------------------------------------

use Netscape::HistoryURL;
use Env qw(HOME);
use Config;
use Carp;


#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION $HOME);

$VERSION = sprintf("%d.%02d", q$Revision: 3.0 $ =~ /(\d+)\.(\d+)/);

#-----------------------------------------------------------------------
#	Private Global Variables
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# The TEMPLATE parameter to use with unpack, when unpacking the visit
# time for a URL. Used in next_url().
#-----------------------------------------------------------------------
my $UNPACK_TEMPLATE    = ($Config{'byteorder'} eq '4321' ? 'V' : 'N');

#-----------------------------------------------------------------------
# The default path for the Netscape history.db database.
#-----------------------------------------------------------------------
my $DEFAULT_HISTORY_DB = "$HOME/.netscape/history.db";

#-----------------------------------------------------------------------
# The default Library for reading the Netscape history.db file.
#-----------------------------------------------------------------------
my $DEFAULT_DBLIB = "DB_File";

#=======================================================================

=head2 CONSTRUCTOR

    $history = new Netscape::History();

This creates a new instance of the Netscape::History object class.
You can optionally pass the path to the history database as an
argument to the constructor, as in:

    $history = new Netscape::History('/home/bob/.netscape/history.db');

If you do not specify the file, then the constructor will use:

    $HOME/.netscape/history.db

If the Netscape history database does not exist, a warning message
will be generated, and the constructor will return C<undef>.

=cut

#=======================================================================
sub import
{
    my($class,%arg) = @_;
    if (exists $arg{dblib}) {
	$DEFAULT_DBLIB = $arg{dblib};
	eval "use $DEFAULT_DBLIB";
	die if $@;
    }
}

sub new
{
    my $class   = shift;

    my $object;
    my $db_filename;
    my %history;


    #-------------------------------------------------------------------
    # The two argument version of bless() enables correct subclassing.
    # See the "perlbot" and "perlmod" documentation in perl distribution.
    #-------------------------------------------------------------------
    $object = bless {}, $class;

    #-------------------------------------------------------------------
    # If there's an argument, then we use that as the path to the
    # history database, otherwise fall back on default.
    #-------------------------------------------------------------------
    if (@_ > 0)
    {
        $db_filename = shift;
    }
    else
    {
        $db_filename = $DEFAULT_HISTORY_DB;
    }

    #-------------------------------------------------------------------
    # If there's an argument, then we use that as the path to the
    # history database, otherwise fall back on default.
    #-------------------------------------------------------------------
    if (-f $db_filename)
    {
	tie %history, $DEFAULT_DBLIB, $db_filename;
	$object->{'HISTORY'} = \%history;
    }
    else
    {
        carp "history file $db_filename not found!\n";
        return undef;
    }

    return $object;
}

#-----------------------------------------------------------------------

=head1 METHODS

The B<Netscape::History> class implements the following methods:

=over

=item *

get_url - get a specific URL from your history

=item *

rewind - reset history database to first URL

=item *

next_url - get next URL from your history

=item *

delete_url - remove a URL from your history

=item *

add_url - add a URL to the history file

=item *

close - close the history database

=back

Each of the methods is described separately below.

=cut

#-----------------------------------------------------------------------

#=======================================================================

=head2 get_url - get a specific URL from your history

    $url = $history->get_url( URL );

This method is used to extract information about a specific URL
from your history database.

This method takes a URL (which could be just a text string,
or an object of class URI::URL) and returns an instance
of Netscape::HistoryURL.

=cut

#=======================================================================
sub get_url
{
    my $self    = shift;
    my $texturl = shift;

    my $value = $self->{'HISTORY'}->{"$texturl\0"};


    return undef unless defined $value;

    return _nh_create_url($texturl, $value);
}

#=======================================================================

=head2 next_url - get the next URL from your history database

    $url = $history->next_url();

This method returns the next URL from your history database.
If you want to process all URLs in the database, you
should call the B<rewind> method before looping over all URLs.

The URL returned is an instance of the Netscape::HistoryURL class,
which works just like an instance of URI::URL, but provides an
extra methods, as described in the documentation for Netscape::HistoryURL.

=cut

#=======================================================================
sub next_url
{
    my $self = shift;

    my $url;
    my $value;


    if (!defined $self->{'HISTORY'})
    {
	warn "next_url(): could not find history database. ",
	     "maybe you already closed it?!\n";
	return undef;
    }

    ($url, $value) = each %{ $self->{'HISTORY'} };

    return undef if !defined $url;

    #-------------------------------------------------------------------
    # The URLs in the history DB have a terminating NULL (\0)!
    #-------------------------------------------------------------------
    chop $url;

    return _nh_create_url($url, $value);
}

#=======================================================================
# _nh_create_url() - internal function, used to create Netscape::HistoryURL
#
# This function is used to generate an instance of Netscape::HistoryURL,
# using the information held in the history database. This function
# encapsulates the handling of differences between the history DB format
# with pre- and post-Netscape 4 versions.
#=======================================================================
sub _nh_create_url
{
    my $url  = shift;
    my $info = shift;

    my $last;
    my $first;
    my $count;
    my $expire;
    my $title;


    if (length($info) > 4)
    {
        ($last, $first, $count, $expire, $title) = unpack("LLLLa*", $info);

        #---------------------------------------------------------------
        # The title has a trailing NULL which we don't want in the string
        #---------------------------------------------------------------
        $title =~ s/\0$//;

        return new Netscape::HistoryURL($url, $last, $first, $count, $expire,
                                        $title);
    }
    else
    {
        return new Netscape::HistoryURL($url, unpack($UNPACK_TEMPLATE,
                                                     $info));
    }
}

#=======================================================================

=head2 delete_url - remove a URL from the history database

    $history->delete_url($url);

This method is used to remove a URL from your history database.
The URL passed can be a simple text string with the URL,
or an instance of Netscape::HistoryURL, URI::URL, or any other
class which can be rendered into a string.

=cut

#=======================================================================
sub delete_url
{
    my $self = shift;
    my $url  = shift;


    if (!defined $self->{'HISTORY'})
    {
	warn "delete_url(): could not find history database. ",
	     "maybe you already closed it?!\n";
	return undef;
    }

    delete $self->{'HISTORY'}->{"$url\0"};
}

#=======================================================================

=head2 add_url - add a URL to the history database

    $history->add_url( URL );

This method is used to add a URL to a history database.
This might be useful if you are merging information from multiple
history databases, for example.

If the URL passed is an instance of Netscape::HistoryURL,
then the information available will be stored.

If the URL is specified as a text string, is derived from URI::URL,
then a Netscape::HistoryURL will be created with the following:

    LAST   = current time
    FIRST  = current time
    COUNT  = 1
    EXPIRE = 1
    TITLE  = ''

If the EXPIRE field is not set to 1, then it won't appear
in Netscape's history window. Not really sure why :-)

=cut

#=======================================================================
sub add_url
{
    my $self = shift;
    my $url  = shift;

    my($first, $last, $count, $expire, $title);


    if ($url->isa('Netscape::HistoryURL'))
    {
        #---------------------------------------------------------------
        # It's of the expected class, so grab out the values we want.
        #---------------------------------------------------------------
        $first  = $url->first_visit_time();
        $last   = $url->last_visit_time();
        $count  = $url->visit_count();
        $expire = $url->expire();
        $title  = $url->title();
    }
    else
    {
        #---------------------------------------------------------------
        # All we've got is the URL, so we put in sensible values for
        # the remaining fields.
        #---------------------------------------------------------------
        $first  = $last = time();
        $count  = 1;
        $expire = 1;
        $title  = '';
    }
    $self->{'HISTORY'}->{"$url\0"} = pack("LLLLa*", $last, $first, $count,
                                          $expire, "$title\0");
}

#=======================================================================

=head2 rewind - reset internal URL pointer to first URL in history

    $history->rewind();

This method is used to move the history database's internal pointer
to the first URL in your history database.
You don't need to bother with this if you have just created the object,
but it doesn't harm anything if you do.

=cut

#=======================================================================
sub rewind
{
    my $self = shift;


    if (!defined $self->{'HISTORY'})
    {
	warn "rewind(): could not find history database. ",
	     "maybe you already closed it?!\n";
	return undef;
    }

    reset %{ $self->{'HISTORY'} };
}

#=======================================================================

=head2 close - close the history database

    $history->close();

This closes the history database. The destructor will do this automatically
for you, so most of time you don't actually have to bother calling this
method explicitly. Good programming style says you should though :-)

=cut

#=======================================================================
sub close
{
    my $self = shift;


    if (!defined $self->{'HISTORY'})
    {
	warn "close(): could not find history database. ",
	     "maybe you already closed it?!\n";
	return undef;
    }

    untie %{ $self->{'HISTORY'} };
    $self->{'HISTORY'} = undef;
}

sub DESTROY
{
    my $self = shift;


    $self->close() if defined $self->{'HISTORY'};
}

#-----------------------------------------------------------------------

=head1 EXAMPLES

=head2 DISPLAY CONTENTS OF HISTORY

The following example illustrates use of this module,
and the B<visit_time()> method of the URLs returned.
The program will list all URLs visited, along with visit time.
The Date::Format module is used to format the visit time.

    #!/usr/bin/perl -w
    
    use Netscape::History;
    use Date::Format;
    use strict;
    
    my $history;
    my $url;
    
    $history = new Netscape::History;
    while (defined($url = $history->next_url() ))
    {
        print "$url :\n";
        print "    First  : ", ctime($url->first_visit_time());
        print "    Last   : ", ctime($url->last_visit_time());
        print "    Count  : ", $url->visit_count(), "\n";
        print "    Expire : ", $url->expire(), "\n";
        print "    Title  : ", $url->title(), "\n";
    }
    $history->close();

=head2 MERGE TWO HISTORY FILES

The following example illustrates use of the C<add_url> method
to merge two history databases. We read all URLs from C<history2.db>,
and merge them into C<history1.db>, overwriting any duplicates.

    $history1 = new Netscape::History("history1.db");
    $history2 = new Netscape::History("history2.db");
    while (defined($url = $history2->next_url() ))
    {
        $history1->add_url($url);
    }
    $history1->close();
    $history2->close();

=head1 SEE ALSO

=over 4

=item L<Netscape::HistoryURL>

When you call the L<next_url> method, you are returned instances of this class.

=item L<DB_File>

The Netscape history file is just a Berkeley DB File,
which we access using the C<DB_File> module. You can
use a different DB_File compatible library (such as
C<DB_File::SV185>) by running

  use Netscape::History dblib => 'DB_File::SV185'

in which case you are only depending on the specified
library and not C<DB_File>.

=item L<URI::URL>

The underlying class for L<Netscape::HistoryURL>,
which provides the mechanisms for manipulating URLs.

=item L<Date::Format>

Functions for formatting time and date in strings.

=back


=head1 AUTHOR

Neil Bowers E<lt>neilb@cre.canon.co.ukE<gt>, and
Richard Taylor E<lt>rit@cre.canon.co.ukE<gt>.

=head1 COPYRIGHT

Copyright (c) 1997-1999 Canon Research Centre Europe. All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#-----------------------------------------------------------------------

1;
