#-----------------------------------------------------------------------

=head1 NAME

Netscape::HistoryURL - URI::URL subclass with Netscape history information

=head1 SYNOPSIS

    use Netscape::HistoryURL;
    
    $url = new Netscape::HistoryURL('http://foobar.com/',
                                    LAST, FIRST, COUNT, EXPIRE, TITLE);

=cut

#-----------------------------------------------------------------------

package Netscape::HistoryURL;
require 5.003;
use strict;

#-----------------------------------------------------------------------

=head1 DESCRIPTION

The C<Netscape::HistoryURL> module subclasses L<URI::URL> to provide
a URL class with methods for accessing the information which is stored
in Netscape's I<history database>.

The history database is used to keep track of all URLs you have visited.
This is used to color previously visited URLs different, for example.
The information stored in the history database depends on the version
of Netscape being used.

=cut

#-----------------------------------------------------------------------

use URI::URL;


#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION $AUTOLOAD);

use overload '""' => 'as_string', 'fallback' => 1;

$VERSION = '2.00';


#-----------------------------------------------------------------------
#	Private Global Variables
#-----------------------------------------------------------------------


#=======================================================================

=head2 CONSTRUCTOR

    $object = new Netscape::HistoryURL( URL,
                                        LAST, FIRST, COUNT, EXPIRE, TITLE );

This creates a new instance of the Netscape::HistoryURL object class.
This supports all the methods supported by the URI::URL class.
Please see the documentation for that module.

The first argument passed is a string which contains a valid URL.
The remaining arguments are information (usually) extracted from Netscape's
history database.

B<LAST> is the time the URL was last visited, and B<FIRST> is the time
when the URL was first visited. B<COUNT> is the number of times you
have visited the URL. We're not really sure what B<EXPIRE> is yet.
B<TITLE> is the title of the referenced page.

You will normally not use the constructor yourself;
it is usually invoked by the C<next_url()> method of the
Netscape::History class.

=cut

#=======================================================================
sub new
{
    my $class   = shift;
    my $url     = shift;
    my $last    = shift;
    my $first   = shift;
    my $count   = shift;
    my $expire  = shift;
    my $title   = shift;

    my $object;


    #-------------------------------------------------------------------
    # The two argument version of bless() enables correct subclassing.
    # See the "perlbot" and "perlmod" documentation in perl distribution.
    #-------------------------------------------------------------------
    $object = bless {}, $class;
    if (defined $object)
    {
	$object->{'LAST_VISIT_TIME'}  = $last;
	$object->{'FIRST_VISIT_TIME'} = $first;
	$object->{'COUNT'}            = $count;
	$object->{'EXPIRE'}           = $expire;
	$object->{'TITLE'}            = $title;
	$object->{'URL'}              = new URI::URL $url;
    }

    return $object;
}

#-----------------------------------------------------------------------

=head1 METHODS

The B<Netscape::HistoryURL> class supports all methods of the URI::URL
class, and additional methods as described below.
Please see the documentation for URI::URL for details of
the other methods supported.

=cut

#-----------------------------------------------------------------------


#=======================================================================

=head2 visit_time - return the time of last visit

    $time = $url->visit_time();

This routine is provided for backwards compatibility with the previous
versions of this module. You should use C<last_visit_time()> instead.

=cut

#-----------------------------------------------------------------------
sub visit_time
{
    my $self = shift;


    return $self->{'LAST_VISIT_TIME'};
}

#=======================================================================

=head2 first_visit_time - the time you first visited the URL

    $time = $url->first_visit_time();

This method returns the time you first visited the URL,
in seconds since the last epoch.
This can then be used with any of the standard routines for formatting
as a string.
The following example uses ctime(), from the Date::Format module:

    print "Time of last visit for $url : ", ctime($url->first_visit_time);

=cut

#-----------------------------------------------------------------------
sub first_visit_time
{
    return $_[0]->{FIRST_VISIT_TIME};
}

#=======================================================================

=head2 last_visit_time - the time you last visited the URL

    $time = $url->last_visit_time();

This method returns the time you last (most recently) visited the URL,
in seconds since the last epoch.

=cut

#-----------------------------------------------------------------------
sub last_visit_time
{
    return $_[0]->{LAST_VISIT_TIME};
}

#=======================================================================

=head2 title - the title of the associated page

    $title = $url->title();

This method returns the title of the referenced page, if one
was available. The value will be C<undef> otherwise.

=cut

#-----------------------------------------------------------------------
sub title
{
    return $_[0]->{TITLE};
}

#=======================================================================

=head2 visit_count - the number of times you have visited the page

    $count = $url->visit_count();

This method returns the number of times you have visited the page.

=cut

#-----------------------------------------------------------------------
sub visit_count
{
    return $_[0]->{COUNT};
}

#=======================================================================

=head2 expire - the expire value for the URL

    $expire = $url->expire();

This method returns the expire values which is stored for the URL.
We don't know what this is for yet, or the right way to interpret it.

=cut

#-----------------------------------------------------------------------
sub expire
{
    return $_[0]->{EXPIRE};
}

#=======================================================================
# as_string() - render instance into a string
#
# We have overloaded string rendering, so that the URL appears as you'd
# expect in a string. We can't just let the AUTOLOAD do this, since the
# overloading seems to require the function exist in this file. Oh well.
#=======================================================================
sub as_string
{
    my $self = shift;


    return $self->{'URL'}->as_string;
}

#=======================================================================
# AUTOLOAD - redirect methods to the URI::URL instance
#
# The AUTOLOAD method is invoked whenever someone tries to invoke a
# method on an instance of this class, where the method is not explicitly
# defined in this file.
#
# We redirect the method to the instance of URI::URL which is camping
# out inside the instance of Netscape::HistoryURL.
#=======================================================================
sub AUTOLOAD
{
    my $self   = shift;

    my $method = $AUTOLOAD;


    $method =~ s/^.*:://;
    return if $method eq 'DESTROY';
    return $self->{'URL'}->$method(@_);
}

#-----------------------------------------------------------------------

=head1 SEE ALSO

=over 4

=item Netscape::History

An object class for accessing the Netscape history database.

=item URI::URL

Base-class, which provides heaps of functionality.

=back


=head1 AUTHOR

Neil Bowers E<lt>neilb@cre.canon.co.ukE<gt> and
Richard Taylor E<lt>rit@cre.canon.co.ukE<gt>.

=head1 COPYRIGHT

Copyright (c) 1997 Canon Research Centre Europe. All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#-----------------------------------------------------------------------

1;
