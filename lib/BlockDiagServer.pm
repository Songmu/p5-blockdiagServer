package BlockDiagServer;
use strict;
use warnings;
use utf8;
use IPC::Run qw/run/;
use File::Temp qw/tempfile/;

sub render {
    my $blockdiag = shift;
    local $| = 1;
    utf8::encode($blockdiag);
    my ($fh, $filename) = tempfile;
    $fh->print($blockdiag);
    $fh->close;

    my $err;
    run ['blockdiag', $filename], undef, undef, \$err or die $err;

    my $png_file = $filename .'.png';
    do {
        local $/;
        open my $fh, '<:raw', $png_file;
        <$fh>
    };

}

1;