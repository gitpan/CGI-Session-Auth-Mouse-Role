use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    package MyApp::Auth;

    use Mouse;
    with qw/CGI::Session::Auth::Mouse::Role/;

    has '_user_key' => (
        is  => 'rw',
        isa => 'Str',
    );

    my %user_info = (
        hoge => {
            password => 'huga',
            age      => 20,
            favorite => 'orange',
        },
        moge => {
            password => 'moga',
            age      => 30,
            favorite => 'apple',
        },
    );
    sub login {
        my $self = shift;
        my ( $username, $password ) = @_;

        if ( exists $user_info{$username} ) {
            $self->_user_key( $username );
            return 1 if ( $user_info{$username} eq $password );
        }
        return;
    }
    sub load_profile {
        my $self = shift;

        my $info = $user_info{$self->_user_key};

        delete $info->{password};
        return $info; # hashref
    }
    sub user_key {
        my $self = shift;
        return $self->_user_key || 0;
    }
}

eval { use CGI; };
if ($@) {
    plan skip_all => "no CGI module";
}

eval { use CGI::Session; };
if ($@) {
    plan skip_all => "no CGI::Session module";
}

my $cgi     = new CGI;
my $session = new CGI::Session( undef, $cgi, { Directory => '/tmp' } );

sub _auth {
    return MyApp::Auth->new(
        cgi     => $cgi,
        session => $session,
    );
}

{
    my $auth = _auth;
    isa_ok($auth,'MyApp::Auth');
}
