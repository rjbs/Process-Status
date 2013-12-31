use strict;
use warnings;
use Test::More;
use Process::Status;

subtest "pid_t == 31488" => sub {
  my $status = Process::Status->new(123 << 8);

  is($status->exitstatus, 123, "exit status 123");
  ok(! $status->signal,        "caught no signal");
  ok(! $status->cored,         "did not dump core");

  is_deeply(
    $status->as_struct,
    { pid_t => 31488, exitstatus => 123, cored => 0 },
    "->as_struct is as expected",
  );

  is($status->as_string, "exited 123", "->as_string is as expected");
};

subtest "pid_t == 395" => sub {
  my $status = Process::Status->new(395);

  is($status->exitstatus,  1, "exit status 1");
  is($status->signal,     11, "caught signal 11");
  ok($status->cored,          "dumped core");

  is_deeply(
    $status->as_struct,
    { pid_t => 395, exitstatus => 1, signal => 11, cored => 1 },
    "->as_struct is as expected",
  );

  is(
    $status->as_string,
    "exited 1, caught SIGSEGV; dumped core",
    "->as_struct is as expected",
  );
};

done_testing;
