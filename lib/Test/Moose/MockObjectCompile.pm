package Test::Moose::MockObjectCompile;
use Moose;
use Symbol;
use Carp;

=head1 Name

    Test::Moose::MockObjectCompile - A Module to help when testing compile time Moose

=head1 SYNOPSIS

    use Test::Moose::MockObjectCompile;
    use Test::More;

    my $mock = Test::Moose::MockObjectCompile->new({package => 'Foo'});
    $mock->roles([qw{Some::Role, Some::Other::Role}]);
    $mock->mock('method1');
    
    lives_ok {$mock->compile} 'Test that roles don't clash and required methods are there';

=head2 ATTRIBUTES

=head2 package

defines a package name for your package. this will be defined on init or an exception will be thrown.

=head2 roles

a list of roles to apply to your package.

=head2 extend

a list of Moose packages you want your package to extend

=head2 base

a package to use as a base (this is a non moose function and I'm not sure it's even needed so it may go away. Let me know if you want it.

=cut

my $VERSION = '0.1';

has 'package' => (is => 'rw', isa => 'Str');
has 'roles'   => (is => 'rw', isa => 'ArrayRef');
has 'extend' => (is => 'rw', isa => 'ArrayRef');
has 'base'    => (is => 'rw', isa => 'Str');

sub BUILD {
    my $self = shift;
    
    $self->{methods} = {};
}

=head1 METHODS

=head2 new

the constructor for a MockObjectCompile(r) it expects a hashref with the package key passed in to define the package name or it will throw an exception.

=cut

around new => sub {
    my $next = shift;
    my ($self, $args) = @_;
    if (!exists $$args{package}) {
       croak('Must pass in a package attribute'); 
    }
    $next->($self, $args);
};

sub _build_code {
    my $self = shift;

    my $pkg = 'package '. $self->package .';';
    $pkg .= " use base '". $self->base . "';" if $self->base;
    $pkg .= ' use Moose;';
    if ($self->roles) {
        foreach (@{$self->roles}) {
            $pkg .= " with '$_';";
        }
    }
    if ($self->extend) {
        foreach (@{$self->extend}) {
            $pkg .= " extends '$_';";
        }
    }
    foreach (keys %{$self->{methods}}) {
        $pkg .= " sub $_ ". $self->{methods}{$_};
    }
    $pkg .= ' 1;';
}

=head2 compile

compiles the module with the definition defined in your roles and extend attributes and whatever you told it to mock.

=cut

sub compile {
    my $self = shift;
    my $pkg = $self->_build_code();
    my $return = eval $pkg;
    die $@ if (!defined $return && $@);
    return $return;
}

sub erase {
    my $self = shift;
    Symbol::delete_package($self->package);
}

=head2 mock 

mocks a method in your compiled Mock Moose Object. It expects a name for the method and an optional string with the code to define the method code you want to compile. It has to be a string and not a coderef because the string will be compiled into the module and adding the method after compile will not test the compile time work that moose does.

 $mock->mock('method1', '{ push @stuff, $_[1];}');

=cut

sub mock {
    my $self = shift;
    my ($name, $code) = @_;
    $code = '{ return 1; }' if (!defined $code);
    $self->{methods}{$name} = $code;
}
=head1 NOTES

Some things to keep in mind are:

this module actually compiles your package this means that any subsequent compiles only modify the package they don't replace it. If you want to make sure you don't have stuff haning around from previouse compiles change the package or make a new instance with a different package name. This way you can be sure you start out with a fresh module namespace.

=head1 AUTHOR

Jeremy Wall <jeremy@marzhillstudios.com>

=head1 COPYRIGHT
    (C) Copyright 2007 Jeremy Wall <Jeremy@Marzhillstudios.com>

    This program is free software you can redistribute it and/or modify it under the same terms as Perl itself.

    See http://www.Perl.com/perl/misc/Artistic.html

=cut
1;
