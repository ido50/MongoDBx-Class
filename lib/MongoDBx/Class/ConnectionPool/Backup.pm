package MongoDBx::Class::ConnectionPool::Backup;

# ABSTARCT: A simple connection pool with a backup connection

our $VERSION = "0.9";
$VERSION = eval $VERSION;

use Moose;
use namespace::autoclean;
use Carp;

with 'MongoDBx::Class::ConnectionPool';

=head1 NAME

MongoDBx::Class::ConnectionPool::Backup - A simple connection pool with a backup connection

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

has 'backup_conn' => (
	is => 'ro',
	isa => 'MongoDBx::Class::Connection',
	writer => '_set_backup',
);

sub get_conn {
	my $self = shift;

	# are there available connections in the pool?
	if (scalar @{$self->pool}) {
		return $self->_take_from_pool;
	}

	# there aren't any, can we create a new connection?
	if ($self->num_used < $self->max_conns) {
		# yes we can, let's create it
		return $self->_get_new_conn;
	}

	# no more connections, return backup conn
	return $self->backup_conn;
}

sub return_conn {
	my ($self, $conn) = @_;

	# do not return the backup connection
	return if $conn->is_backup;

	# only add connection if pool isn't full, otherwise discard it
	if (scalar @{$self->pool} + $self->num_used - 1 < $self->max_conns) {
		$self->_add_to_pool($conn);
		$self->_inc_used(-1);
	}
}

sub BUILD {
	my $self = shift;

	my %params = %{$self->params};
	$params{is_backup} = 1;
	$self->_set_backup(MongoDBx::Class::Connection->new(%params));
}

sub _take_from_pool {
	my $self = shift;

	my $pool = $self->pool;
	my $conn = shift @$pool;
	$self->_set_pool($pool);
	$self->_inc_used;
	return $conn;
}

around 'get_conn' => sub {
	my ($orig, $self) = @_;

	return $self->$orig || $self->backup_conn;
};

__PACKAGE__->meta->make_immutable;
