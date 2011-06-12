#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use POSIX qw(setsid);
use IPC::PerlSSH;

my $ssh_host    = 'localhost';
my $ssh_port    = 22992;
my $ssh_user    = 'mgreb';
my $growlnotify = '/usr/local/bin/growlnotify';

# daemonize so we are non-blocking
chdir '/' or exit 1;
open STDIN,  '/dev/null'   or exit 1;
open STDOUT, '>>/dev/null' or exit 1;
open STDERR, '>>/dev/null' or exit 1;
defined( my $pid = fork ) or exit 1;
exit if $pid;
setsid or exit 1;

alarm 20;

my $ips = IPC::PerlSSH->new(
    Host    => $ssh_host,
    Port    => $ssh_port,
    User    => $ssh_user
);

$ips->use_library('Run', 'system');
$ips->call( 'system', $growlnotify, @ARGV );
