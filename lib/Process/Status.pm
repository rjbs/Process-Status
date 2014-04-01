use strict;
use warnings;
package Process::Status;
# ABSTRACT: a handle on process termination, like $?

use Config ();

=head1 OVERVIEW

When you run a system command with C<system> or C<qx``> or a number of other
mechanisms, the process termination status gets put into C<$?> as an integer.
In C, it's a value of type C<pid_t>, and it stores a few pieces of data in
different bits.

Process::Status just provides a few simple methods to make it easier to
inspect.  Almost the sole reason it exists is for its C<as_struct> method,
which can be passed to a pretty printer to dump C<$?> in a somewhat more
human-readable format.

Methods called on C<Process::Status> without first calling a constructor will
work on an implicitly-constructed object using the current value of C<$?>.  To
get an object for a specific value, you can call C<new> and pass an integer.
You can also call C<new> with no arguments to get an object for the current
value of C<$?>, if you want to keep that ugly variable out of your code.

=method new

  my $ps = Process::Status->new( $pid_t );
  my $ps = Process::Status->new; # acts as if you'd passed $?

=cut

sub _self { ref $_[0] ? $_[0] : $_[0]->new($?); }

sub new {
  my $pid_t = defined $_[1] ? $_[1] : $?;
  return bless \$pid_t, $_[0] if $pid_t >= 0;

  return bless [ $pid_t, "$!", 0+$! ], 'Process::Status::Negative';
}

=method pid_t

This returns the value of the C<pid_t> integer, as you might have found in
C<$?>.

=cut

sub pid_t {
  ${ $_[0]->_self }
}

=method is_success

This method returns true if the C<pid_t> is zero.

=cut

sub is_success  { ${ $_[0]->_self } == 0 }

=method exitstatus

This method returns the exit status of the C<pid_t>.

=cut

sub exitstatus { ${ $_[0]->_self } >> 8   }

=method signal

This returns the signal caught by the process, or zero.

=cut

sub signal     { ${ $_[0]->_self } & 127 }

=method cored

This method returns true if the process dumped core.

=cut

sub cored      { !! (${ $_[0]->_self } & 128) }

=method as_struct

This method returns a hashref describing the status.  Its exact contents may
change over time; it is meant for human, not computer, consumption.

=cut

sub as_struct {
  my $self = $_[0]->_self;

  my $pid_t = $self->pid_t;

  return {
    pid_t => $pid_t,
    ($pid_t == -1 ? () : (
      exitstatus => $pid_t >> 8,
      cored      => ($pid_t & 128) ? 1 : 0,

      (($pid_t & 127) ? (signal => $pid_t & 127) : ())
    )),
  };
}

my %SIGNAME;
sub __signal_name {
  my ($signal) = @_;
  unless (%SIGNAME) {
    my @names = split /\x20/, $Config::Config{sig_name};
    $SIGNAME{$_} = "SIG$names[$_]" for (1 .. $#names);
  }

  return($SIGNAME{ $signal } || "signal $signal");
}

sub as_string {
  my $self  = $_[0]->_self;
  my $pid_t = $$self;
  my $str  = "exited " . ($pid_t >> 8);
  $str .= ", caught " . __signal_name($pid_t & 127) if $pid_t & 127;
  $str .= "; dumped core" if $pid_t & 128;

  return $str;
}

{
  package Process::Status::Negative;

  BEGIN { our @ISA = 'Process::Status' }
  sub pid_t { $_[0][0] }
  sub is_success { return }
  sub exitstatus { $_[0][0] }
  sub signal     { 0 }
  sub cored      { return }

  sub as_struct {
    return {
      pid_t    => $_[0][0],
      strerror => $_[0][1],
      errno    => $_[0][2],
    }
  }

  sub as_string {
    qq{did not run; \$? was $_[0][0], \$! was "$_[0][1]" (errno $_[0][2])}
  }
}

1;
