use Test::More tests => 1;

BEGIN {
    use_ok( 'CGI::Session::Auth::Mouse::DBI' );
}

diag( "Testing CGI::Session::Auth::Mouse::DBI $CGI::Session::Auth::Mouse::DBI::VERSION" );

use CGI::Session::Auth::Mouse::DBI;
