use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'blockdiagSever',
    AUTHOR        => 'Some Person <person@example.com>',
    VERSION_FROM  => 'app.psgi',
    PREREQ_PM     => {
        'Amon2'                           => '2.52',
        'Text::Xslate'                    => '1.4001',
        'Text::Xslate::Bridge::TT2Like'   => '0.00008',
        'Plack::Middleware::ReverseProxy' => '0.09',
        'Time::Piece'                     => '1.20',
        'MIME::Base64'                    => '3.12',
        'MIME::Types'                     => '0.01',
        'Cache::Memcached::Fast'          => '0.01',
        'Cache::Memcached::IronPlate'     => '0.01',
        'IPC::Run'                        => '0.01',
        'File::Temp'                      => '0.01',
    },
    MIN_PERL_VERSION => '5.012000',
    (-d 'xt' and $ENV{AUTOMATED_TESTING} || $ENV{RELEASE_TESTING}) ? (
        test => {
            TESTS => 't/*.t xt/*.t',
        },
    ) : (),
);
