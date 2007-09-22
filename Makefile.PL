use inc::Module::Install;

name 'Test-Moose-MockObjectCompile';

perl_version    '5.006';
all_from 'lib/Test/Moose/MockObjectCompile.pm';

abstract    'Test-Moose-MockObjectCompile - a Helper module for testing compile time Moose stuff';
version     '0.1';

requires        'Moose';
requires        'Moose::Role';
requires        'Symbol';
requires        'Carp';

build_requires        'Test::Moose';
build_requires        'Test::More';
build_requires        'Test::Exception';

auto_install;
WriteAll;
