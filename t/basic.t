#!perl
use v5.28.0;
use warnings;
use experimental 'signatures';

use lib 'lib', 't/lib';

use Test::More;

use IO::Async::Test;
use Synergy::Tester;

my $result = Synergy::Tester->testergize({
  reactors => {
    echo => { class => 'Synergy::Reactor::Echo' },
    pref => { class => 'Synergy::Reactor::Preferences' },
  },
  default_from => 'alice',
  users => {
    alice   => undef,
    charlie => undef,
  },
  todo => [
    [ send    => { text => "synergy: Hi." }  ],
    [ wait    => { seconds => 0.1  }  ],
    [ repeat  => { text => "synergy: Hello?", times => 3, sleep => 0.34 } ],
    [ wait    => { seconds => 0.1  }  ],
    [ send    => { text => "synergy: Bye." } ],
  ],
});

my @sent = $result->synergy->channel_named('test-channel')->sent_messages;

is(@sent, 5, "five replies recorded");

is(  $sent[0]{address}, 'public',                    "1st: expected address");
like($sent[0]{text},    qr{I heard you, .* "Hi\."},  "1st: expected text");

is(  $sent[4]{address}, 'public',                    "5th: expected address");
like($sent[4]{text},    qr{I heard you, .* "Bye\."}, "5th: expected text");

subtest 'run_process' => sub {
  my $done;

  my $hub = $result->synergy;
  my $f = $hub->run_process([ '/usr/bin/uptime' ]);

  $f->on_done(sub ($ec, $stdout, $stderr) {
    $done = 1;
    is($ec, 0, 'process exited successfully');
    like($stdout, qr{load average}, 'got a reasonable stdout');
    is($stderr, '', 'empty stdout');
  });

  wait_for { $done };
};

done_testing;
