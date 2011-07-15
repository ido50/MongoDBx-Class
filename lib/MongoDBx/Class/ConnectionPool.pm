package MongoDBx::Class::ConnectionPool;

# ABSTARCT: A simple connection pool for MongoDBx::Class

our $VERSION = "0.9";
$VERSION = eval $VERSION;

use Moose::Role;
use namespace::autoclean;
use Carp;

=head1 NAME

MongoDBx::Class::ConnectionPool - A simple connection pool for MongoDBx::Class

=head1 SYNOPSIS

	# create a MongoDBx::Class object normally:
	use MongoDBx::Class;
	my $dbx = MongoDBx::Class->new(namespace => 'MyApp::Model::DB');

	# instead of connection, create a rotated pool
	my $pool = $dbx->pool(max_conns => 200, type => 'pool'); # max_conns defaults to 100

	# or, if you need to pass attributes to MongoDB::Connection->new():
	my $pool = $dbx->pool(max_conns => 200, type => 'pool', params => {
		host => $host,
		username => $username,
		password => $password,
	});

	# get a connection from the pool on a per-request basis
	my $conn = $pool->get_conn;

	# ... do stuff with $conn and return it when done ...

	$pool->return_conn($conn);

=head1 DESCRIPTION

WARNING: connection pooling via MongoDBx::Class is experimental. It is a
quick, simple implementation that may or may not work as expected.

MongoDBx::Class::ConnectionPool is a very simple interface for creating
MongoDB connection pools. The basic idea is: create a pool with a maximum
number of connections as a setting. Give connections from the pool on a per-request
basis. The pool is empty at first, and connections are created for each
request, until the maximum is reached. The behaviour of the pool when this
maximum is reached is dependant on the implementation. There are currently
two implementations:

=over

=item * Rotated pools (L<MongoDBx::Class::ConnectionPool::Rotated>) - these
pools hold at most the number of maximum connections defined. An index is
held, initially starting at zero. When a request for a connection is made,
the connection located at the current index is returned (if exists, otherwise
a new one is created), and the index is raised. When the index reaches the
end of the pool, it returns to the beginning (i.e. zero), and the next
request will receive the first connection in the pool, and so on. This means
that every connection in the pool can be shared by an unlimited number of
requesters.

=item * Backup pools (L<MongoDBx::Class::ConnectionPool::Backup>) - these
pools expect the receiver of a connection to return it when they're done
using it. If no connections are available when a request is made (i.e.
all connections are currently used), a backup connection is returned (there
can be only one backup connection). This means that every connection in
the pool can be used by one requester, except for the backup connection.

=back

The rotated pool makes more sense for pools with a relatively low number
of connections, while the backup pool is more fit for a larger number of
connections. The selection should be based, among other factors, on your
application's metrics: how many end-users (e.g. website visitors) use your
application concurrently? does your application experience periods of
larger usage numbers at certain points of the day/week? does it make more
sense for you to balance work between a predefined number of connections
(rotated pool) or do you prefer each end-user to get its own connection
(backup pool)?

At any rate, every end-user will receive a connection, shared or not.

=head1 ATTRIBUTES

=cut

has 'max_conns' => (
	is => 'ro',
	isa => 'Int',
	default => 100,
);

has 'pool' => (
	is => 'ro',
	isa => 'ArrayRef[MongoDBx::Class::Connection]',
	writer => '_set_pool',
	default => sub { [] },
);

has 'num_used' => (
	is => 'ro',
	isa => 'Int',
	writer => '_set_used',
	default => 0,
);

has 'params' => (
	is => 'ro',
	isa => 'HashRef',
	required => 1,
);

requires 'get_conn';
requires 'return_conn';

sub _get_new_conn {
	my $self = shift;

	my $conn = MongoDBx::Class::Connection->new(%{$self->params});
	$self->_inc_used;
	return $conn;
}

sub _inc_used {
	my ($self, $int) = @_;

	$int ||= 1;
	$self->_set_used($self->num_used + $int);
}

sub _add_to_pool {
	my ($self, $conn) = @_;

	my $pool = $self->pool;
	push(@$pool, $conn);
	$self->_set_pool($pool);
}

1;
