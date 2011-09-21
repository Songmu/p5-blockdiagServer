use strict;
use warnings;
use utf8;
use 5.12.0;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Plack::Builder;
use Amon2::Lite;
use MIME::Base64::URLSafe;
use Cache::Memcached::Fast;
use Cache::Memcached::IronPlate;
use BlockDiagServer;

# put your configuration here
sub config {
    state $config;
    $config ||= do 'config/config.pl';
    $config;
}

sub cache {
    my $self = shift;
    state $memd;
    $memd ||= Cache::Memcached::IronPlate->new(
        cache   => Cache::Memcached::Fast->new({
            servers => $self->config->{servers}{cache},
        }),
    );
    $memd;
}

# base64 ex 'ewogIEEgLT4gQiAtPiBDOwogIEIgLT4gRDsKfQ'
get '/blockdiag/:base64' => sub {
    my ($c, $args) = @_;
    my $base64 = $args->{base64};
    my $png = $c->cache->get($base64);

    unless ($png) {
        my $block_diag = urlsafe_b64decode($base64);
        $png = BlockDiagServer::render($block_diag);
        $c->cache->set($base64 => $png);
    }

    $c->create_response(200, ['Content-Type' => 'image/png'], $png);
};

get '/demo' => sub {
    my $c = shift;
    $c->render('demo.tt');
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
__DATA__
@@ demo.tt
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<title>title</title>
<script type="text/javascript" src="/static/js/base64.js"></script>
<script type="text/javascript">
function $(id) {return document.getElementById(id);};
</script>
</head>
<body>
<img src="" id="blockdiagimg">
<textarea id="blockdiag" rows="20" cols="100">{
  A -> B -> C;
       B -> D;
}</textarea>
<input type="button" value="生成" onclick="(function(){
  $('blockdiagimg').src = '/blockdiag/' + Base64.encode($('blockdiag').value);
})()"/>
</body>
</html>
