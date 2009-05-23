use inc::Module::Install;

name 'CGI-Session-Auth-Mouse-Role';
all_from 'lib/CGI/Session/Auth/Mouse/Role.pm';

requires 'Mouse';
requires 'CGI';
requires 'CGI::Session';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
