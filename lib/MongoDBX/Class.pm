package MongoDBX::Class;

# ABSTRACT: Flexible ORM for MongoDB databases

use Moose;
use namespace::autoclean;
use MongoDB;
use MongoDBX::Class::Connection;
use MongoDBX::Class::Database;
use MongoDBX::Class::Collection;
use MongoDBX::Class::Cursor;
use MongoDBX::Class::Reference;
use Carp;

has 'namespace' => (is => 'ro', isa => 'Str', required => 1);

has 'conn' => (is => 'ro', isa => 'MongoDB::Connection', predicate => 'is_connected', writer => '_set_conn', clearer => '_clear_conn');

has 'doc_classes' => (is => 'ro', isa => 'HashRef', default => sub { {} });

=head1 NAME

MongoDBX::Class - Flexible ORM for MongoDB databases

=head1 SYNOPSIS

	use MongoDBX::Class;

=head1 DESCRIPTION

=head1 CLASS METHODS

=head1 new( namespace => $namespace )

Creates a new instance of this module. Requires the namespace of the
database schema to use. The schema will be immediately loaded, but no
connection to a database is made yet.

=cut

sub BUILD {
	shift->_load_schema;
}

=head1 ATTRIBUTES

=head2 namespace

A string representing the namespace of the MongoDB schema used (e.g.
C<MyApp::Schema>. Your document classes, structurally speaking, should be
descendants of this namespace (e.g. C<MyApp::Schema::Article>,
C<MyApp::Schema::Post>).

=head1 OBJECT METHODS

=head2 connect( [host => $host], [port => $port] )

Initiates a new connection to a MongoDB server running on a certain host
and listening to a certain port, and sets the working database. If a host
is not provided, 'localhost' is used. If a port is not provided, 27017
(MongoDB's default port) is used. The database name is required.

=cut

sub connect {
	my ($self, %opts) = @_;

	$opts{host} ||= 'localhost';
	$opts{port} ||= 27017;

	$self->_set_conn(MongoDBX::Class::Connection->new(host => $opts{host}, port => $opts{port}, doc_classes => $self->doc_classes));
}

=head1 INTERNAL METHODS

=cut

sub _load_schema {
	my $self = shift;

	# load the classes
	require Module::Pluggable;
	Module::Pluggable->import(search_path => [$self->namespace], require => 1, sub_name => '_doc_classes');
	foreach ($self->_doc_classes) {
		my $name = $_;
		$name =~ s/$self->{namespace}:://;
		$self->doc_classes->{$name} = $_;
	}
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-MongoDBX::Class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBX::Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBX::Class

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongoDBX::Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongoDBX::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongoDBX::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/MongoDBX::Class/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;
