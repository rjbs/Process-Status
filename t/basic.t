use strict;
use warnings;
use Test::More;
use Process::Status;

my $status = Process::Status->new(123 << 8);

is($status->exitstatus, 123);
is($status->signal,       0);
is($status->cored,        0);

is_deeply(
  $status->as_struct,
  { pid_t => 31488, exitstatus => 123, signal => 0, cored => 0 },
);

done_testing;
