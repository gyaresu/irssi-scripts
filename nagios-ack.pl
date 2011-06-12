#!/usr/bin/perl
use strict;
use vars qw($VERSION %IRSSI);


# probably not very useful for other people but who knows?

$VERSION = "0.0.1";
%IRSSI = (
    authors     => 'mikegrb',
    contact     => 'michael@thegrebs.com',
    name        => 'nagios-ack',
    description => 'ack nagios alerts in irc',
    license     => 'GPLv2',
    url         => '',
    changed     => '20110429',
    modules     => ''
);

my $last_alert;

sub on_public {
    my ($server, $msg, $nick, $addr, $target) = @_;
    return unless $target eq '#linode-staff' && $nick eq 'linagios';
    $last_alert = $msg if $msg =~ m/^PROBLEM/;
    return;
}

sub nagios_ack {
    my ( undef, $server, $window ) = @_;
    my @issue = parse_status();
    if (!@issue) {
        $window->print("Failed to parse last status: $last_alert");
    }
    my $message = 'linagios: ack ' . join ' ', reverse @issue;
    $window->command('MSG #linode-staff ' . $message);
}

sub nagios_status {
    my (undef, undef, $window) = @_;
    my $issue = join ',', map { "'" . $_ . "'" } reverse parse_status();
    $window->print("Last issue: '$last_alert' ($issue)");

}

sub parse_status {
    return $1 if $last_alert =~ /^PROBLEM - (\S+) is DOWN/;
    return ($1, $2) if $last_alert =~ /^PROBLEM - (\S+) on (\S+) is/;
    return;
}

sub nagios_inject {
    $last_alert = shift;
}
Irssi::signal_add_first("message public", "on_public");
Irssi::command_bind( 'ack',     \&nagios_ack );
Irssi::command_bind( 'nagstat', \&nagios_status );
Irssi::command_bind( 'naginj',  \&nagios_inject );

1;
