#-----------------------------------------------------------------------

=head1 NAME

Netscape::HistoryURL - subclass of URI::URL which provides visit time

=head1 SYNOPSIS

    use Netscape::HistoryURL;
    
    $url = new Netscape::HistoryURL('http://foobar.com/', $time);

=cut

#-----------------------------------------------------------------------

package Netscape::HistoryURL;
require 5.003;
use strict;

#-----------------------------------------------------------------------

=head1 DESCRIPTION

The C<Netscape::HistoryURL> module subclasses L<URI::URL> to provide
a URL class with a method for accessing visit time.

=cut

#-----------------------------------------------------------------------

use URI::URL;


#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION $AUTOLOAD %OVERLOAD);

use overload '""' => 'as_string', 'fallback' => 1;

$VERSION = '1.001';


#-----------------------------------------------------------------------
#	Private Global Variables
#-----------------------------------------------------------------------


#=======================================================================

=head2 CONSTRUCTOR

    $object = new Netscape::HistoryURL( URL, TIME );

This creates a new instance of the Netscape::HistoryURL object class.
This supports all the methods supported by the URI::URL class.
Please see the documentation for that module.

The first argument passed is a string which contains a valid URL.
The second argument is the time of visit, in seconds since the last epoch.

=cut

#=======================================================================
sub new
{
    my $class   = shift;
    my $url     = shift;
    my $time    = shift;

    my $object;


    #-------------------------------------------------------------------
    # The two argument version of bless() enables correct subclassing.
    # See the "perlbot" and "perlmod" documentation in perl distribution.
    #-------------------------------------------------------------------
    $object = bless {}, $class;
    if (defined $object)
    {
	$object->{'VISIT_TIME'} = $time;
	$object->{'URL'}        = new URI::URL $url;
    }

    return $object;
}

#-----------------------------------------------------------------------

=head1 METHODS

The B<Netscape::HistoryURL> class implements the following methods:

=over

=item *

B<visit_time> returns the time you last visited the URL.

=item URI::URL methods

All the methods of the URI::URL class are supported.
See the documentation for that module.

=back

The methods specific to this class are further described below.

=cut

#-----------------------------------------------------------------------


#=======================================================================

=head2 visit_time - return the time of last visit

    $time = $url->visit_time();

This method returns the time you last visited the URL,
in seconds since the last epoch.
This can then be used with any of the standard routines for formatting
as a string.
The following example uses ctime(), from the Date::Format module:

    print "Time of last visit for $url : ", ctime($url->visit_time);

=cut

#-----------------------------------------------------------------------
sub visit_time
{
    my $self = shift;


    return $self->{'VISIT_TIME'};
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

Neil Bowers E<lt>neilb@cre.canon.co.ukE<gt>

=head1 COPYRIGHT

Copyright (c) 1997 Canon Research Centre Europe. All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#-----------------------------------------------------------------------

1;
