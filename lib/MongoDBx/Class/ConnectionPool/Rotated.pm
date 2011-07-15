package MongoDBx::Class::ConnectionPool::Rotated;

# ABSTARCT: A simple connection pool with rotated connections

our $VERSION = "0.9";
$VERSION = eval $VERSION;

use Moose;
use namespace::autoclean;
use Carp;
use Try::Tiny;

with 'MongoDBx::Class::ConnectionPool';

=head1 NAME

MongoDBx::Class::ConnectionPool::Rotated - A simple connection pool with rotated connections

=head1 SYNOPSIS

	# create a MongoDBx::Class object normally:
	use MongoDBx::Class;
	my $dbx = MongoDBx::Class->new(namespace => 'MyApp::Model::DB');

	# instead of connection, create a pool
	my $pool = $dbx->pool(max_conns => 200); # max_conns defaults to 100

	# or, if you need to pass attributes to MongoDB::Connection->new():
	my $pool = $dbx->pool(max_conns => 200, params => {
		host => $host,
		username => $username,
		password => $password,
	});

	# get a connection from the pool on a per-request basis
	my $conn = $pool->get_conn;

	# ... do stuff with $conn and return it when done ...

	$pool->return_conn($conn);

=head1 DESCRIPTION

MongoDBx::Class::Connection extends L<MongoDB::Connection>. This class
provides the document expansion and collapsing methods that are used
internally by other MongoDBx::Class classes.

Note that a L<MongoDBx::Class> object can only have one connection at a
time. Connection is only made via the C<connect()> method in MongoDBx::Class.

=head1 ATTRIBUTES

=cut

sub get_conn {
	my $self = shift;

	# are there available connections in the pool?
	if (scalar @{$self->pool} == $self->max_conns && $self->num_used < $self->max_conns) {
		return $self->_take_from_pool;
	}

	# there aren't any, can we create a new connection?
	if ($self->num_used < $self->max_conns) {
		# yes we can, let's create it
		return $self->_get_new_conn;
	}

	# no more connections, rotate to the beginning
	$self->_set_used(0);
	return $self->_take_from_pool;
}

sub return_conn { return }

sub _take_from_pool {
	my $self = shift;

	my $conn = $self->pool->[$self->num_used];
	$self->_inc_used;
	return $conn;
}

around '_get_new_conn' => sub {
	my ($orig, $self) = @_;

	my $conn = $self->$orig;
	my $pool = $self->pool;
	push(@$pool, $conn);
	$self->_set_pool($pool);
	return $conn;
};

__PACKAGE__->meta->make_immutable;
