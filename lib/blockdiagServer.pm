package blockdiagServer;
use strict;
use warnings;
use utf8;
use IPC::Run qw/run/;
use File::Temp qw/tempfile/;

sub render {
    my ($blockdiag, $cmd) = @_;
    $cmd ||= 'blockdiag';
    utf8::encode($blockdiag) if utf8::is_utf8($blockdiag);
    my (undef, $filename) = tempfile;

    my $err;
    run [$cmd, '-o', $filename, '-'], \$blockdiag, undef, \$err or die $err;

    do {
        local $/;
        open my $fh, '<:raw', $filename or die 'no file';
        <$fh>
    };

}

1;
