#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use POSIX qw(setsid);

alarm 20;

# daemonize so we are non-blocking
chdir '/' or exit 1;
open STDIN,  '/dev/null'   or exit 1;
open STDOUT, '>>/dev/null' or exit 1;
open STDERR, '>>/dev/null' or exit 1;
defined( my $pid = fork ) or exit 1;
exit if $pid;
setsid or exit 1;

system '/usr/bin/ssh', 'mgreb@localhost', '-p 22992',
    '/usr/local/bin/growlnotify', @ARGV;
