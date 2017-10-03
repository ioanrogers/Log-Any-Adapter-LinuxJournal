package Log::Any::Adapter::LinuxJournal;

# ABSTRACT: Log::Any adapter for the systemd journal on Linux

use v5.12;
use warnings;

use Linux::Systemd::Journal::Write;
use Log::Any::Adapter::Util '1.700';
use base 'Log::Any::Adapter::Base';

sub init {
    my $self = shift;
    $self->{jnl} = Linux::Systemd::Journal::Write->new(@_);
    return;
}

sub structured {
    my ($self, $level, $category, @args) = @_;

    my %details = (
        PRIORITY => $level,
        CATEGORY => $category,
    );

    my @msg;
    while (my $arg = shift @args) {

        # TODO journal can only usefully take k => v, flatten v
        if (!ref $arg) {
            push @msg, $arg;
        } elsif (ref $arg eq 'HASH') {
            @details{keys %{$arg}} = values %{$arg};
        } elsif (ref $arg eq 'ARRAY') {
            while (my ($k, $v) = (shift @{$arg}, shift @{$arg})) {
                $details{$k} = $v;
            }
        } else {
            push @msg, Log::Any::Adapter::Util::dump_one_line($arg);
        }
    }

    $self->{jnl}->send(join(' ', @msg), \%details);

    return;
}

# TODO optionally disable debug
for my $method (Log::Any::Adapter::Util::detection_methods()) {
    no strict 'refs';    ## no critic
    *$method = sub {1};
}

1;

=head1 SYNOPSIS

  use Log::Any::Adapter;
  Log::Any::Adapter->set('LinuxJournal',
      # app_id => 'myscript', # default is basename($0)
  );

=head1 DESCRIPTION

B<WARNING> This is a L<Log::Any> adpater for I<structured> logging, which means it
is only useful with a very recent version of L<Log::Any>, at least C<1.700>

It will log messages to the systemd journal via L<Linux::Systemd::Journal::Write>.

=head1 SEE ALSO

L<Log::Any::Adapter::Journal>
