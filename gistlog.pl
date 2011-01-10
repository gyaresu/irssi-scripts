#!/usr/bin/perl
use strict;
use vars qw($VERSION %IRSSI);

use POSIX;

$VERSION = "0.0.1";
%IRSSI = (
    authors     => 'mikegrb',
    contact     => 'michael@thegrebs.com',
    name        => 'gistlog',
    description => 'post lastlog match as a gist on github',
    license     => 'GPLv2',
    url         => '',
    changed     => '20100109',
    modules     => ''
);

my $pipe_tag;
my $has_gist_module = 0;
check_gist_module();

sub gistlog {
    my ( $search, $undef, $window ) = @_;

    unless ($search) {
        Irssi::print("usage: /gistlog <lastlog args>");
        return;
    }

    my $temp_file = "/tmp/gistlog-$$";
    unlink $temp_file if -e $temp_file;
    Irssi::command("lastlog -window $window->{name} -file $temp_file $search");

    my $match_text;
    {
        open my $fh, '<', $temp_file;
        local $/ = undef;
        $match_text = <$fh> if $fh;
    }
    unless ($match_text) {
        $window->print("No match text returned by lastlog");
        return;
    }

    return unless check_gist_module();

    my ( $user, $token ) = (
        Irssi::settings_get_str('github_username'),
        Irssi::settings_get_str('github_token') );
    unless ( $user && $token ) {
        Irssi::print('Must /set github_username and github_token');
        return;
    }

    my $gist = WWW::GitHub::Gist->new( user => $user, token => $token );
    $gist->add_file( 'irssi lastlog: ' . $search, $match_text, '.weechatlog' );

    my ( $rh, $wh );
    pipe( $rh, $wh );
    defined( my $pid = fork ) or die "Can't fork: $!";
    if ($pid) {
        Irssi::pidwait_add($pid);
        $pipe_tag = Irssi::input_add( fileno($rh), INPUT_READ,
            sub { send_result( $rh, $window ) }, 'urmom' );
        return;
    }

    my $result = $gist->create;

    unless ( ref $result eq 'ARRAY'
        && ref $result->[0] eq 'HASH'
        && exists $result->[0]->{repo} )
    {
           print $wh "something went wrong, sorry";
    }

    else {
        my $url = 'https://gist.github.com/' . $result->[0]->{repo};
        print $wh "Gist created: $url";
    }
    POSIX::_exit(0);
}

sub send_result {
    my ( $fh, $window ) = @_;

    my $input = <$fh>;
    close $fh;
    return unless $input;

    Irssi::input_remove($pipe_tag);
    $window->print($input);
}

sub check_gist_module {
    return 1 if $has_gist_module;
    eval { require WWW::GitHub::Gist; };
    if ($@) {
        Irssi::print("This script requires WWW::GitHub::Gist, try again.");
    }
    else { $has_gist_module = 1; }
    return $has_gist_module;
}

Irssi::command_bind( 'gistlog', \&gistlog );

Irssi::settings_add_str( 'gistlog', 'github_username', '' );
Irssi::settings_add_str( 'gistlog', 'github_token',    '' );

1;
