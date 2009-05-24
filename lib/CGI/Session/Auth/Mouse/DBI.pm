package CGI::Session::Auth::Mouse::DBI;

=head1 NAME

CGI::Session::Auth::Mouse::DBI - Authenticated sessions for CGI scripts

=head1 VERSION

This document describes CGI::Session::Auth::Mouse::DBI version 0.0.1

=head1 SYNOPSIS

    use CGI;
    use CGI::Session;
    use CGI::Session::Auth::Mouse::DBI;

    my $cgi     = new CGI;
    my $session = new CGI::Session(undef, $cgi, {Directory=>'/tmp'});
    my $auth    = CGI::Session::Auth::Mouse::DBI->new(
        cgi     => $cgi,
        session => $session,
        dsn     => 'DBI:mysql:cgiauth:localhost:3306',
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

=head1 DEFAULT TABLE

    CREATE TABLE auth_user (
        id int(11) NOT NULL,
        username varchar(255) NOT NULL,
        passward varchar(255) NOT NULL default '',
        -- md5_hex value
        PRIMARY KEY (id),
        UNIQUE username (username)
    );

=head1 Constructor parameters

Additional to the standard parameters used by the C<new> constructor of
all CGI::Session::Auth::Mouse::Role classes,
CGI::Session::Auth::Mouse::DBI understands the following parameters:

=over 1

=cut

use warnings;
use strict;
use 5.008_001;
use Carp;

use version;
our $VERSION = qv('0.0.3');

use Mouse;
use DBI;
use Digest::MD5 qw( md5_hex );

with qw/CGI::Session::Auth::Mouse::Role/;

=item B<db_handle>: Active database handle.

=item B<dsn>: Data source name for the database connection. (Default: none)
For an explanation, see the L<DBI> documentation.

=item B<db_user>: Name of the user account used for the database connection. (Default: none)

=item B<db_password>: Password of the user account used for the database connection. (Default: none)

=item B<db_port>: Connection Port of the user account used for the database connection. (Default: 3306)

=item B<db_attr>: Optional attributes used for the database connection. (Default: none)

=item B<user_table>: Name of the table containing the user authentication data and profile. (Default: 'users')

=item B<user_name_field>: Name of the column username field. (Default: 'username')

=item B<user_pass_field>: Name of the column password field. (Default: 'password')

=back

=head1 METHODS

=over 4

=cut

has 'db_handle'   => ( is => 'rw', isa => 'DBI::db' );
has 'dsn'         => ( is => 'rw', isa => 'Str' );
has 'db_user'     => ( is => 'rw', isa => 'Str' );
has 'db_password' => ( is => 'rw', isa => 'Str' );
has 'db_port'     => ( is => 'rw', isa => 'Int', default => 3306 );
has 'db_attr'     => ( is => 'rw', isa => 'HashRef' );

has 'user_table'      => ( is => 'rw', isa => 'Str', require => 1, default => 'users' );
has 'user_name_field' => ( is => 'rw', isa => 'Str', require => 1, default => 'username' );
has 'user_pass_field' => ( is => 'rw', isa => 'Str', require => 1, default => 'password' );

has 'profiles' => ( is => 'rw', isa => 'HashRef' );

=item login

CGI::Session::Auth::Mouse::Role requires this method.

=cut

sub login {
    my $self = shift;
    my ( $username, $password ) = @_;

    $password = $self->_encode_password( $password );

    $self->_set_db_handle();
    my $query = sprintf(
        'SELECT * FROM %s WHERE %s=? AND %s=?',
        $self->user_table,
        $self->user_name_field,
        $self->user_pass_field,
    );
    my $sth = $self->db_handle->prepare( $query );
    $sth->execute( $username, $password ) or croak $self->db_handle->errstr;
    if ( my $row = $sth->fetchrow_hashref ) {
        $self->_set_profile( $row );
        return 1;
    }
    return;
}

sub _encode_password {
    my ( $self, $password ) = @_;
    return md5_hex( $password );
}

sub _set_db_handle {
    my $self = shift;

    if ( !$self->db_handle ) {
        my $dbh = DBI->connect(
            $self->dsn,         $self->db_user,
            $self->db_password, $self->db_attr,
        ) or croak( "DB connect error: " . $DBI::errstr );

        $self->db_handle($dbh)
    }
}

sub _set_profile {
    my ( $self, $row ) = shift;

    delete $row->{$self->user_pass_field};
    $self->profiles( $row );
}

=item load_profile

CGI::Session::Auth::Mouse::Role requires this method.

=cut

sub load_profile { return shift->profiles(); }

1;
__END__

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-cgi-session-auth-mouse-role@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head2 DEPENDENCIES

L<CGI::Session::Auth::Mouse::Role>
L<DBI>
L<Digest::MD5>

=head1 SEE ALSO

L<CGI::Session::Auth::DBI>
L<CGI::Session::Auth::Mouse::Role>
L<DBI>

=head1 AUTHOR

<noblejasper>  C<< <<nobjas@gmail.com>> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, <noblejasper> C<< <<nobjas@gmail.com>> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
