use strict;
use warnings;
use LWP::UserAgent;
use File::Slurp;
use Time::HiRes qw(gettimeofday tv_interval);
use Parallel::ForkManager;
use Getopt::Long;
use File::Basename;
use Term::ANSIColor;
use POSIX qw(strftime);

# ASCII Art
my $ascii_art = << "ASCII";
    ____                       _ 
   / ___|   ___     ___     __| |
  | |      / _ \\   / _ \\   / _` |
  | |___  | (_) | | (_) | | (_| |
   \\____|  \\___/   \\___/   \\__,_|
   
ASCII

print $ascii_art;

# Command-line options
my $verbose = 0;
my $concurrency = 1;
my $retry_count = 3;
my $help = 0;

GetOptions(
    "verbose"       => \$verbose,
    "concurrency=i" => \$concurrency,
    "retries=i"     => \$retry_count,
    "help"          => \$help,
) or die("Error in command line arguments\n");

if ($help) {
    print "Usage: perl script.pl [options] <filename> <url>\n";
    print "Options:\n";
    print "  --verbose             Enable detailed output\n";
    print "  --concurrency=n       Number of concurrent requests (default: 1)\n";
    print "  --retries=n           Number of retries for failed requests (default: 3)\n";
    print "  --help                Show this help message\n";
    exit(0);
}

sub handleError {
    my ($err) = @_;
    if ($err) {
        open my $fh, '>>', 'error.log' or die "Could not open error.log: $!";
        my $timestamp = strftime "%Y-%m-%d %H:%M:%S", localtime;
        print $fh "[$timestamp] Error Found: $err\n";
        close $fh;
        die "Error Found: $err\n";
    }
}

sub logSuccess {
    my ($message) = @_;
    open my $fh, '>>', 'success.log' or die "Could not open success.log: $!";
    my $timestamp = strftime "%Y-%m-%d %H:%M:%S", localtime;
    print $fh "[$timestamp] $message\n";
    close $fh;
}

sub logFailure {
    my ($message) = @_;
    open my $fh, '>>', 'failure.log' or die "Could not open failure.log: $!";
    my $timestamp = strftime "%Y-%m-%d %H:%M:%S", localtime;
    print $fh "[$timestamp] $message\n";
    close $fh;
}

sub scanLines {
    my ($filename) = @_;
    my @lines = read_file($filename, chomp => 1);
    return @lines;
}

sub Tester {
    if (@ARGV < 2) {
        print "Usage: perl script.pl [options] <filename> <url>\n";
        exit(1);
    }

    my $filename = $ARGV[0];
    my $url = $ARGV[1];
    my @words = scanLines($filename);
    my $total_words = scalar @words;

    my $ua = LWP::UserAgent->new;

    my $pm = Parallel::ForkManager->new($concurrency);

    foreach my $word (@words) {
        $pm->start and next;  # Fork a process

        my $attempts = 0;
        my $success = 0;

        while ($attempts < $retry_count && !$success) {
            $attempts++;
            my $start_time = [gettimeofday];
            my $response = $ua->get("$url/$word");
            my $elapsed = tv_interval($start_time);
            my $timestamp = strftime "%Y-%m-%d %H:%M:%S", localtime;

            if ($response->is_success) {
                my $message = "Word: $word, URL: $url/$word, Status: " . $response->code . ", Time: ${elapsed}s, Success";
                print color('green') . "[$timestamp] $message\n" . color('reset');
                logSuccess($message);
                $success = 1;
            } else {
                my $error_message = "Word: $word, URL: $url/$word, Status: " . $response->status_line . ", Time: ${elapsed}s, Failed, Attempt: $attempts";
                print color('red') . "[$timestamp] $error_message\n" . color('reset') if $verbose;
                logFailure($error_message) if $attempts == $retry_count;
            }
        }

        $pm->finish;  # End the forked process
    }

    $pm->wait_all_children;

    print "All URLs tested\n";
}

Tester();
