package MongoDBx::Class::Meta::AttributeTraits;

# ABSTRACT: Attribute traits provided by MongoDBx::Class

our $VERSION = "0.9";
$VERSION = eval $VERSION;

=head1 NAME

MongoDBx::Class::Meta::AttributeTraits - Attribute traits provided by MongoDBx::Class

=cut

package MongoDBx::Class::Meta::AttributeTraits::Parsed;

# ABSTRACT: An attribute trait for attributes automatically expanded and collapsed by a parser class.

our $VERSION = "0.9";
$VERSION = eval $VERSION;

use Moose::Role;
use namespace::autoclean;

=head1 NAME

MongoDBx::Class::Meta::AttributeTraits::Parsed - An attribute trait for attributes automatically expanded and collapsed by a parser class.

=cut

has 'parser' => (is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_parser {
	'MongoDBx::Class::ParsedAttribute::'.shift->{isa};
}

{
	package Moose::Meta::Attribute::Custom::Trait::Parsed;
	sub register_implementation { 'MongoDBx::Class::Meta::AttributeTraits::Parsed' }
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
