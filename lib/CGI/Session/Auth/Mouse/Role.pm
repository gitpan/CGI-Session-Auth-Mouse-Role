package CGI::Session::Auth::Mouse::Role;

=head1 NAME

CGI::Session::Auth::Mouse::Role - Role for authentication of CGI::Session Module

=head1 VERSION

This document describes CGI::Session::Auth::Mouse::Role version 0.0.3

=head1 SYNOPSIS

    BEGIN {
        package MyApp::Auth;

        use Mouse;

        with qw/CGI::Session::Auth::Mouse::Role/;

        has 'user_info' => ( is => 'ro', isa => 'HashRef',
            default => sub {
                return {
                    hoge => {
                        password => 'huga',
                        age      => 20,
                        favorite => 'orange',
                    },
                    moge => {
                        password => 'moga',
                        age      => 30,
                        favorite => 'apple',
                    }
                };
            },
        );
        has 'profiles' => ( is => 'rw', isa => 'HashRef' );

        sub login {
            my $self = shift;
            my ( $username, $password ) = @_;
            if ( exists $self->user_info->{$username} ) {
                $self->_set_profile($self->user_info->{$username});
                return 1 if ( $self->user_info->{$username}->{password} eq $password );
            }
            return;
        }
        sub _set_profile {
            my ( $self, $info ) = @_;
            delete $info->{password};
            $self->profile( $info );
        }
        sub load_profile { return shift->profile; }
    }
    my $auth = MyApp::Auth->new(
        cgi     => new CGI,
        session => new Session,
    );
    $auth->authenticate();
    if ( $auth->logged_in ) {
        ## show secret page
    }
    else {
        ## show login page
    }

=head1 SAMPLE HTML

    <form method="POST" action="sample.cgi">
        <input type="text" name="login_username" />
        <input type="password" name="login_password" />
        <input type="submit" value="submit" />
    </form>

=head1 METHODS

=over 4

=cut

use warnings;
use strict;
use 5.008_001;
use Carp;

use version;
our $VERSION = qv('0.0.7');

use Mouse::Role;
use constant {
    LOGIN_KEY => '~logged_in',
    TRIAL_KEY => '~login_trial',
};

has 'prefix'    => ( is => 'ro', isa => 'Str',
    require => 1,
    default => 'login_',
);

has 'logged_in' => ( is => 'rw', isa => 'Bool',
    require => 1,
    default => 0,
);

has 'session'   => ( is => 'ro', isa => 'CGI::Session',
    require => 1,
    default => sub {
        my $class = 'CGI::Session';
        Mouse::load_class($class);
        $class->new;
    },
);

has 'cgi'     => ( is => 'ro', isa => 'CGI',
    require => 1,
    default => sub {
        my $class = 'CGI';
        Mouse::load_class($class);
        $class->new;
    },
);

requires qw/login load_profile/;


=item authenticate

authenticate method

=cut

sub authenticate {
    my $self = shift;

    # already session
    if ( $self->session->param(LOGIN_KEY) ) {
        $self->_set_logged_in(1); # set flag
    }
    else {
        $self->_no_session_authenticate();
    }
    return; # authenticate done
}

=item logged_in

Returns a boolean value representing the current visitors authentication status.

=item logout

logout method

=cut

sub logout {
    my $self = shift;
    $self->_set_logged_in(0);
}

###########################################################
###
### internal methods
###
###########################################################

sub _no_session_authenticate {
    my $self = shift;

    my $lg_name = $self->cgi->param( $self->prefix . "username" );
    my $lg_pass = $self->cgi->param( $self->prefix . "password" );

    if ( $lg_name && $lg_pass ) {
        if ( $self->login( $lg_name, $lg_pass ) ) {
            $self->_set_logged_in(1); # set flag
            $self->_set_session_params();
        }
        else {
            $self->_fail_login();
        }
    }
}

sub _fail_login {
    my $self = shift;

    $self->_set_logged_in(0); # reset flag
    my $trials = $self->session->param(TRIAL_KEY) || 0;
    $self->session->param(TRIAL_KEY, ++$trials);
}

sub _set_session_params {
    my $self = shift;

    $self->session->clear([TRIAL_KEY]);
    $self->_set_session_profile();
}

sub _set_session_profile {
    my $self = shift;

    my $profiles = $self->load_profile();
    foreach my $key ( keys %{ $profiles } ) {
        $self->session->param( $key, $profiles->{$key} );
    }
}

sub _set_logged_in {
    my ( $self, $flag ) = @_;

    if ( defined $flag ) {
        $self->logged_in( $flag );
        if ( $self->logged_in ) {
            $self->session->param(LOGIN_KEY, "1");
        }
        else {
            $self->session->clear([LOGIN_KEY]);
        }
    }
    return $self->logged_in;
}

1; # Magic true value required at end of module
__END__

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-cgi-session-auth-mouse-role@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head2 DEPENDENCIES

L<Mouse>
L<Mouse::Role>
L<CGI::Session>

=head1 SEE ALSO

L<CGI::Session>
L<CGI::Session::Auth>
L<Mouse>
L<Mouse::Role>

=head1 AUTHOR

<noblejasper>  C<< <<nobjas@gmail.com>> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, <noblejasper> C<< <<nobjas@gmail.com>> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
