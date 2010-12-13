package Mongofy;

use Moose;
use namespace::autoclean;
use MongoDB;
use Carp;

# ABSTRACT: Flexible ORM for MongoDB databases.

has 'namespace' => (is => 'ro', isa => 'Str', required => 1);

has 'colls' => (is => 'ro', isa => 'HashRef', default => sub { {} });

has 'conn' => (is => 'ro', isa => 'MongoDB::Connection', predicate => 'is_connected', writer => '_set_conn', clearer => '_clear_conn');

has 'db' => (is => 'ro', isa => 'MongoDB::Database', predicate => 'has_db', writer => '_set_db', clearer => '_clear_db');

=head1 NAME

Mongofy - Flexible ORM for MongoDB databases.

=head1 SYNOPSIS

	use Mongofy;

	my $db = Mongofy->new( namespace => 'MyApp::Schema' );
	$db->connect(host => 'localhost', port => 27017, database => 'db_name');

=head1 DESCRIPTION

=head1 CLASS METHODS

=head1 new( namespace => $namespace )

Creates a new instance of this module. Requires the namespace of the
database schema to use. The schema will be immediately loaded, but no
connection to a database is made yet.

=cut

after 'new' => sub {
	shift->_load_schema;
}

=head1 ATTRIBUTES

=head2 namespace

A string representing the namespace of the MongoDB schema used (e.g.
C<MyApp::Schema>. Your document classes, structurally speaking, should be
descendants of this namespace (e.g. C<MyApp::Schema::Article>,
C<MyApp::Schema::Post>).

=head2 colls

A hash-ref of all collection/document-class objects loaded from your schema.
To be more specific, every object in this hash-ref is a Moose class that
implements the L<Mongofy::Document> or L<Mongofy::EmbeddedDocument>
roles. The keys of this hash-ref are the package names of the document
classes, minus the namespace, so the key for the C<MyApp::Schema::Article>
document class, for example, is C<Article>.

=head1 OBJECT METHODS

=head2 connect( database => $db_name, [host => $host], [port => $port] )

Initiates a new connection to a MongoDB server running on a certain host
and listening to a certain port, and sets the working database. If a host
is not provided, 'localhost' is used. If a port is not provided, 27017
(MongoDB's default port) is used. The database name is required.

=cut

sub connect {
	my ($self, %opts) = @_;

	croak "You must provide a MongoDB database name to use with Mongofy."
		unless $opts{database};

	$opts{host} ||= 'localhost';
	$opts{port} ||= 27017;

	my $conn = MongoDB::Connection->new(host => $opts{host}, port => $opts{port});
	$self->_set_conn($conn);
	$self->_set_db($conn->get_database($opts{database});
}

=head2 coll( $name )

Returns the collection object named C<$name>. This is the package name
of the collection class, minus the namespace, so C<MyApp::Schema::Person>
simply becomes C<Person>.

=cut

sub coll {
	my ($self, $name) = @_;

	croak "You must provide the name of the Mongofy collection to fetch."
		unless $name;

	return $self->colls->{$name};
}

=head1 INTERNAL METHODS

=cut

sub _load_schema {
	my $self = shift;

	# load the classes
	require Module::Pluggable;
	Module::Pluggable->import(search_path => [$self->namespace], instantiate => 'new', sub_name => 'doc_classes');
	foreach ($self->doc_classes) {
		my $name = ref $_;
		$name =~ s/$self->{namespace}:://;
		$self->colls->{$name} = $_;
	}
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongofy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mongofy>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Mongofy

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mongofy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mongofy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mongofy>

=item * Search CPAN

L<http://search.cpan.org/dist/Mongofy/>

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
