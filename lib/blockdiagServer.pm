package blockdiagServer;
use strict;
use warnings;
use utf8;
use IPC::Run qw/run/;
use File::Temp qw/tempfile/;

sub render {
    my $blockdiag = shift;
    local $| = 1;
    utf8::encode($blockdiag) if utf8::is_utf8($blockdiag);
    my ($fh, $filename) = tempfile;
    $fh->print($blockdiag);
    $fh->close;

    my $err;
    run ['blockdiag', $filename], undef, undef, \$err or die $err;

    my $png_file = $filename .'.png';
    do {
        local $/;
        open my $fh, '<:raw', $png_file or die 'no file';
        <$fh>
    };

}

1;
