#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use strict;

use Irssi;

our $VERSION = '0.1';
our %IRSSI   = (
    authors     => 'Michael Greb',
    contact     => 'michael@thegrebs.com mikegrb @ irc.(perl|oftc).net',
    name        => 'local-growl',
    description => 'Sends out Growl notifications',
    license     => 'BSD',
);

my $GROWL_COMMAND = "/home/michael/bin/growlnotify";

sub send_growl {
    my ( $title, $message, $notification ) = @_;

    return if ( !Irssi::settings_get_bool('growl_enabled') );

    # lame shell escaping due to the pass throush ssh to remote shell
    $title   = escape_and_wrap($title);
    $message = escape_and_wrap($message); 

    notify( {
        name    => 'irssi',
        image   => '/Users/mgreb/Documents/irssi.png',
        title   => $title,
        subject => $message
    } );
}

sub on_message_private {
    my ( $server_rec_ref, $msg, $nick, $address ) = @_;

    return if ( !Irssi::settings_get_bool('growl_show_private_messages') );

    my $title = "$nick sent a private message";
    send_growl( $title, $msg, 'Private message' );
}

sub on_print_text {
    my ( $text_dest_rec_ref, $text, $stripped ) = @_;

    if ( Irssi::settings_get_bool('growl_show_hilights')
        && ( $text_dest_rec_ref->{'level'} & MSGLEVEL_HILIGHT ) )
    {   my $title = 'Highlight in ' . $text_dest_rec_ref->{'target'};
        send_growl( $title, $stripped, 'Hilight' );
    }
}

sub escape_and_wrap {
    my $text = shift;
    $text =~ s/'/\\'/g;
    return "'$text'";
}

## notify from Growl::Tiny 0.0.3 by Alex White (wu) retrieved 2011-06-11 at
## http://cpansearch.perl.org/src/VVU/Growl-Tiny-0.0.3/lib/Growl/Tiny.pm
sub notify {
    my $options;

    if ( ref $_[0] eq "HASH" ) {
        $options = $_[0];
    }
    else {
        $options = \%_;
    }

    # skip notifications with no subject
    return unless $options->{subject};

    # skip notifications with the 'quiet' flag set
    return if $options->{quiet};

    #
    # build the command line options
    #
    my @command_line_args = ( $GROWL_COMMAND );

    if ( $options->{sticky} ) {
        push @command_line_args, '-s';
    }

    push @command_line_args, ( '-n', $options->{name} || 'Growl::Tiny' );

    if ( $options->{priority} ) {
        push @command_line_args, ( '-p', $options->{priority} );
    }

    my $host = $options->{host} || $ENV{GROWL_HOST};
    if ( $host ) {
        push @command_line_args, ( '-H', $host );
    }

    if ( $options->{image} ) {
        push @command_line_args, ( '--image', $options->{image} );
    }

    push @command_line_args, ( '-m', $options->{subject} );

    if ( $options->{title} ) {
        push @command_line_args, ( '-t', $options->{title} );
    }

    if ( $options->{identifier} ) {
        push @command_line_args, ( '-d', $options->{identifier} );
    }

    # Irssi::print("COMMAND: " . join " ", @command_line_args, "\n");
    return system( @command_line_args ) ? 0 : 1;
}

Irssi::settings_add_bool( $IRSSI{'name'}, 'growl_show_private_messages', 1 );
Irssi::settings_add_bool( $IRSSI{'name'}, 'growl_show_hilights',         1 );
Irssi::settings_add_bool( $IRSSI{'name'}, 'growl_sticky',  0 );
Irssi::settings_add_bool( $IRSSI{'name'}, 'growl_enabled', 0 );

Irssi::signal_add_last( 'message private', 'on_message_private' );
Irssi::signal_add_last( 'print text',      'on_print_text' );
Irssi::signal_add_last( 'setup changed',   'on_setup_changed' );

Irssi::print( $IRSSI{name} . ' ' . $VERSION . ' loaded' );
Irssi::print(
    'growl_enabled is Off by default. Set it to On when you have configured the server and optionally the password'
) unless Irssi::settings_get_bool('growl_enabled');

1;