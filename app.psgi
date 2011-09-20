use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Plack::Builder;
use Amon2::Lite;
use MIME::Base64::URLSafe;
use Cache::Memcached::Fast;
use Cache::Memcached::IronPlate;

# put your configuration here
sub config {
    state $config;
    $config ||= do 'config/config.pl';
    $config;
}

sub cache {
    my $self = shift;
    state $memd;
    $mend ||= Cache::Memcached::IronPlate->new(
        cache   => Cache::Memcached::Fast->new({
            servers => $self->config->{servers}{cache},
        }),
    );
    $mend;
}

get '/:base64' => sub {
    my ($c, $args) = @_;
    my $block_diag = urlsafe_b64decode($args->{base64});

};

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;
        $res->header( 'X-Content-Type-Options' => 'nosniff' );
    },
);

# load plugins
use HTTP::Session::Store::File;
__PACKAGE__->load_plugins(
    'Web::CSRFDefender',
    'Web::HTTPSession' => {
        state => 'Cookie',
        store => HTTP::Session::Store::File->new(
            dir => File::Spec->tmpdir(),
        )
    },
);

builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/static/|/robot\.txt$|/favicon.ico$)},
        root => File::Spec->catdir(dirname(__FILE__));
    enable 'Plack::Middleware::ReverseProxy';

    __PACKAGE__->to_app();
};

