package blockdiagServer;
use strict;
use warnings;
use utf8;
use IPC::Run qw/run/;
use File::Temp;

sub render {
    my ($blockdiag, $cmd, $type) = @_;
    $cmd ||= 'blockdiag';
    $type ||= 'png';

    utf8::encode($blockdiag) if utf8::is_utf8($blockdiag);
    my $fh = File::Temp->new(UNLINK => 1, suffix => ".$type");
    $fh->close;
    my $filename = $fh->filename;
    my $err;
    run [$cmd, '--antialias', '-T', $type, '-o', $filename, '-'], \$blockdiag, undef, \$err or die $err;

    do {
        local $/;
        open my $fh, '<:raw', $filename or die 'no file';
        <$fh>
    };

}

1;
