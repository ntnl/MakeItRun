#!/usr/bin/perl
################################################################################
# 
# Make It Run - periodically check and re-spawn stuff, as needed.
#
# Copyright (C) 2011 Bartłomiej BS502 Syguła
#
# This is free software.
# It is licensed, and can be distributed under the same terms as Perl itself.
#
# More information on: http://bs502.pl/Projects/
# 
################################################################################
use strict; use warnings; # {{{

use English qw( -no_match_vars );
use Getopt::Long;
use Proc::ProcessTable;
# }}}

our $VERSION = q{1.0};

exit main();

=pod

=encoding UTF-8

=head1 NAME

Make It Run - periodically check and re-spawn stuff, as needed.

=head1 SYNOPSIS

 */15 * * * * myuser ./make_it_run.pl --count 2 --kill -- /usr/bin/perl /home/myuser/Project/my_project.pl --client

=head1 DESCRIPTION

Purpose of this script is to maintain a pool of processes running at constantly.

The script should be run periodically, for example by I<cron>-like service.

If there is no I<cron> around, it can be triggered by any other means necessarily, for example from I<.cgi> script or I<procmail> filter.

=head1 OPTIONS

=over

=item -h --help

Display short usage summary, including all command line options, and exit.

=item -V --version

Display program version, and exit.

=item -p --pretend

Do not run/kill anything, just check and say what WOULD be done.

This implies verbose mode (no need to add -v).

=item -v --verbose

Makes the script describe what it's doing. Otherwise, the script is quiet.

=item -c --count

Number of instances of the command that should be running. By default it's 1.

Please, do not set this to a high value!

=item -k --kill

If there are more instances of the command running, then set on the command line,
allow the script to terminate them by sending the TERM signal.

Otherwise, if there are more instances then configured, script does nothing.

=item --

This is not really an option, but a separator that indicates that from this point all
items belong to the command being handled.

=back

=head1 NOTES

Please, note that checking if a command - with fixed set of arguments - is running is not a trivial problem under Linux.
To make the script work reliable, please follow the guidelines bellow:

=over

=item Wrap it...

If you command has a lot of command line options, or uses glob characters (* and ?),
write a simple F<runme.sh> shell script/wrapper for your command.

=item User matters

Script looks for commands running as it's own user. If another user has identical command
running, script will ignore it.

Please double-check if you run the script from the correct user.

=item Interpreter scripts

If your command is a script, please run it trough the interpreter directly,
for example: F</usr/bin/perl foo.pl> instead of simply F<foo.pl>.

=back

=cut

sub main { # {{{
    my %opts = (
        help    => 0,
        version => 0,

        pretend => 0,
        verbose => 0,

        count => 1,
        kill  => 0,
    );

    if (not scalar @ARGV) {
        @ARGV = q{--help};
    }

    GetOptions(
        'h|help'    => \$opts{'help'},
        'V|version' => \$opts{'version'},

        'p|pretend' => \$opts{'pretend'},
        'v|verbose' => \$opts{'verbose'},

        'c|count=i' => \$opts{'count'},
        'k|kill'    => \$opts{'kill'},
    );
    my @command = @ARGV;

    if ($opts{'help'}) {
        print "Make It Run - check if given command is running, and if not - run it.\n";
        print "\n";
        print "Usage:\n";
        print "\n";
        print "  \$ make_it_run.pl [options] [--] command\n";
        print "\n";
        print "  -h  --help     Display this summary.\n";
        print "  -V  --version  Display script version.\n";
        print "\n";
        print "  -p  --pretend  Do not do anything, just say what would be done. Enables verbocity.\n";
        print "  -v  --verbose  Say what is happening.\n";
        print "\n";
        print "  -c  --count=n  Maintain at least n instances of the command. Default: 1.\n";
        print "  -k  --kill=n   Kill excessive instances of the command. Default: no.\n";

        exit 0;
    }

    if ($opts{'version'}) {
        print "Make It Run Version $VERSION\n";

        exit 0;
    }

    if ($opts{'pretend'}) {
        $opts{'verbose'} = 1;
    }

    my $command_string = join " ", @command;

    if ($opts{'verbose'}) {
        print "Command:\n  $command_string\n";
    }

    my $proc_table = new Proc::ProcessTable;

    my $count = 0;
    foreach my $process (@{ $proc_table->table() }) {
        if ($process->uid() != $EUID) {
            # This is not 'our' process. Ignore.
            next;
        }

        if ($process->cmndline() eq $command_string) {
            $count++;

            if ($opts{'kill'} and $count > $opts{'count'}) {
                if ($opts{'verbose'}) {
                    print "Killing: (pid:".$process->pid().")\n  ". $process->cmndline() ."\n";
                }

                if (not $opts{'pretend'}) {
                    kill "TERM", $process->pid();
                }

                $count--;
            }
        }
    }

    if ($opts{'verbose'}) {
        print "Found $count running instances.\n";
    
        if ($count >= $opts{'count'}) {
            print "No need to run anything.\n";
        }
    }

    while ($count < $opts{'count'}) {
        if ($opts{'verbose'}) {
            print "Running:\n  $command_string\n";
        }

        if (not $opts{'pretend'}) {
            system $command_string .q{ >/dev/null 2>&1 &};
        }

        $count++;
    }

    if ($opts{'verbose'}) {
        print "Done :)\n";
    }

    return 0;
} # }}}

=head1 INSTALLATION / UPDATE

At this point I assume, that you have a working Perl 5.10 or newer installed.

1) Download the script, from L<http://bs502.pl/static/Perl/make_it_run.pl>.

2) Make it executable, for example by running I<chmod +x make_it_run.pl>.

3) Install dependencies: F<Proc::ProcessTable>.

4) Configure and use according to taste.

=head1 COPYRIGHT

Copyright (C) 2011 Bartłomiej /Natanael/ Syguła

This is free software.
It is licensed, and can be distributed under the same terms as Perl itself.

More information on: L<http://bs502.pl/Projects/>

=cut

# vim: fdm=marker
