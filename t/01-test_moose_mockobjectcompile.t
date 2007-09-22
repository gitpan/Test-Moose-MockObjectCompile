use Test::More;
use Test::Exception;
use Test::Moose;

package Test::Role1;
use Moose::Role;

1;
package Test::Role2;
use Moose::Role;

requires 'Baz';
excludes 'Test::Role1';

1;
package main;

BEGIN: {
    plan tests => 19;

    use_ok('Test::Moose::MockObjectCompile');
}

{
    has_attribute_ok('Test::Moose::MockObjectCompile', 'package');
    has_attribute_ok('Test::Moose::MockObjectCompile', 'roles');
    has_attribute_ok('Test::Moose::MockObjectCompile', 'extend');
    has_attribute_ok('Test::Moose::MockObjectCompile', 'base');
    
    can_ok('Test::Moose::MockObjectCompile', qw{_build_code compile mock});
    
}

my $mock;
{
    throws_ok {Test::Moose::MockObjectCompile->new()}
       qr/Must pass in a package attribute/, 
        'Instance without a package attribute throws an error';
    lives_ok {$mock = Test::Moose::MockObjectCompile->new({package => 'Foo'})} 
        'Instance with a package attribute succeeds';
    is($mock->package, 'Foo', 'Package is set to Foo');
    
    is($mock->_build_code, 'package Foo; use Moose; 1;', 'code to compile is correct');
    $mock->base('Bar');
    is($mock->_build_code, "package Foo; use base 'Bar'; use Moose; 1;", 'code with base to compile is correct');
    $mock->{base} = undef;
    $mock->roles([qw{Bar Baz}]);
    is($mock->_build_code, "package Foo; use Moose; with 'Bar'; with 'Baz'; 1;", 'code with roles to compile is correct');
    $mock->extend([qw{FooBar}]);
    is($mock->_build_code, "package Foo; use Moose; with 'Bar'; with 'Baz'; extends 'FooBar'; 1;", 'code with roles and extends to compile is correct');
    $mock->mock(doit => '{ return 1;}'); 
    is($mock->_build_code, "package Foo; use Moose; with 'Bar'; with 'Baz'; extends 'FooBar'; sub doit { return 1;} 1;", 'code with roles and extends and methods to compile is correct');
    dies_ok {$mock->compile} 'compile of fictional module dies';

    #test that the compile succeeds when it should
    my $mock2 = Test::Moose::MockObjectCompile->new({package => 'Tester'});
    $mock2->roles([qw{Test::Role1}]);
    lives_ok {$mock2->compile} 'compile of valid role requirement succeeds';
    $mock2->roles([qw{Test::Role2}]);
    dies_ok {$mock2->compile} 'compile of role with missing required method dies';
    $mock2->mock('Baz');
    $mock2->package('Tester2');
    lives_ok {$mock2->compile} 'compile of valid role with required method succeeds';
    $mock->roles([qw{Test::Role2 Test::Role1}]);
    $mock->mock('Baz');
    $mock->{methods} = {};
    dies_ok {$mock->compile} 'compile of role with clashing roles dies';
}
