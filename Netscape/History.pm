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
require 5.003;
use strict;

#-----------------------------------------------------------------------

=head1 DESCRIPTION

The C<Netscape::History> module implements an object class for
accessing the history database maintained by the Netscape web browser.
The history database keeps a list of all URLs you have visited,
and is used by Netscape to change the color of URLs which you have
previously visited, for example.

=cut

#-----------------------------------------------------------------------

use DB_File;
use Netscape::HistoryURL;
use Env qw(HOME);
use Config;


#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION $HOME);

$VERSION = '1.000';

#-----------------------------------------------------------------------
#	Private Global Variables
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# The TEMPLATE parameter to use with unpack, when unpacking the visit
# time for a URL. Used in next_url().
#-----------------------------------------------------------------------
my $UNPACK_TEMPLATE = ($Config{'byteorder'} eq '4321' ? 'V' : 'N');


#=======================================================================

=head2 CONSTRUCTOR

    $history = new Netscape::History();

This creates a new instance of the Netscape::History object class.


=cut

#=======================================================================
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

    $db_filename = "$HOME/.netscape/history.db";
    if (-f $db_filename)
    {
	tie %history, 'DB_File', $db_filename;
	$object->{'HISTORY'} = \%history;
    }
    else
    {
        warn "no history db found!\n";
        return undef;
    }

    return $object;
}

#-----------------------------------------------------------------------

=head1 METHODS

The B<Netscape::History> class implements the following methods:

=over

=item *

rewind - reset history database to first URL

=item *

next_url - get next URL from your history

=item *

delete_url - remove a URL from your history

=item *

close - close the history database

=back

Each of the methods is described separately below.

=cut

#-----------------------------------------------------------------------

#=======================================================================

=head2 next_url - get the next URL from your history database

    $url = $history->next_url();

This method returns the next URL from your history database.
If you want to process all URLs in the database, you
should call the B<rewind> method before looping over all URLs.

The URL returned is an instance of the Netscape::HistoryURL class,
which works just like an instance of URI::URL, but provides an
extra method B<visit_time()>.
This returns the time of your last visit to that URL.

=cut

#=======================================================================
sub next_url
{
    my $self = shift;

    my $url;
    my $time;


    if (!defined $self->{'HISTORY'})
    {
	warn "next_url(): could not find history database. ",
	     "maybe you already closed it?!\n";
	return undef;
    }

    ($url, $time) = each %{ $self->{'HISTORY'} };

    return undef if !defined $url;

    #-------------------------------------------------------------------
    # The URLs in the history DB have a terminating NULL (\0)!
    #-------------------------------------------------------------------
    chop $url;

    return new Netscape::HistoryURL($url, unpack($UNPACK_TEMPLATE, $time));
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

=head1 EXAMPLE PROGRAM

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
        print "$url : ", ctime($url->visit_time());
    }
    $history->close();


=head1 SEE ALSO

=over 4

=item L<Netscape::HistoryURL>

When you call the L<next_url> method, you are returned instances of this class.

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

Copyright (c) 1997 Canon Research Centre Europe. All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#-----------------------------------------------------------------------

1;
