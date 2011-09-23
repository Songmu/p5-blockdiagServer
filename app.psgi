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
use MIME::Base64 qw/decode_base64url/;
use MIME::Types qw/by_suffix/;
use Cache::Memcached::Fast;
use Cache::Memcached::IronPlate;
use blockdiagServer;

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

my $diagrams = [qw/blockdiag nwdiag actdiag seqdiag/];
my $types = [qw/png svg pdf/];

get '/demo/:diagram' => sub {
    my ($c, $args) = @_;
    my $diagram = $args->{diagram};
    return $c->res_404 unless $diagram ~~ $diagrams;

    $c->render('demo.tt', {diagram => $diagram, diagrams => $diagrams});
};


# base64 ex 'ewogIEEgLT4gQiAtPiBDOwogIEIgLT4gRDsKfQ'
get '/:diagram/:base64' => sub {
    my ($c, $args) = @_;
    my $base64 = $args->{base64};
    $base64 =~ s/\.png$//i;

    my $diagram = $args->{diagram};
    return $c->res_404 unless $diagram ~~ $diagrams;

    my $cache_key = "$diagram-$base64";
    my $image = $c->cache->get($cache_key);

    ($base64, my $ext) = $base64 =~ /^([^.]*)(?:\.(.*))?$/;
    $ext ||= 'png';
    $ext = lc $ext;
    return $c->res_404 unless $ext ~~ $types;

    unless ($image) {
        my $diag_text = decode_base64url $base64;
        # TODO: validate
        $image = blockdiagServer::render($diag_text, $diagram, $ext);
        $c->cache->set($cache_key => $image);
    }
    return $c->res_404 unless $image;

    my $mime_type = by_suffix $ext;
    $c->create_response(200, ['Content-Type' => $mime_type], $image);
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
<title>[% diagram %]</title>
<script type="text/javascript" src="/static/js/base64.js"></script>
<script type="text/javascript">
function $(id) {return document.getElementById(id);};
</script>
</head>
<body>
<h1>[% diagram %]</h1>
[% FOREACH di IN diagrams -%]
 <a href="/demo/[% di %]">[% di %]</a> |
[% END -%]
<div><img src="" id="blockdiagimg"></div>
<textarea id="blockdiag" rows="20" cols="100">{
  A -> B -> C;
       B -> D;
}</textarea>
<input type="button" value="生成" onclick="(function(){
  $('blockdiagimg').src = '/[% diagram %]/' + Base64.encode($('blockdiag').value);
})()"/>
</body>
</html>
