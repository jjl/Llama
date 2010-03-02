use MooseX::Declare;

class Llama::Exception::Trace::DebugItem extends Llama::Exception::Trace::Item {
    has args => (
        isa => 'Maybe[ArrayRef]',
        is => 'ro',
        required => 1,
    );
    has my_vars => (
        is => 'ro',
        required => 1,
    );
    has our_vars => (
        is => 'ro',
        required => 1,
    );
    has hasargs => (
        is => 'ro',
        required => 1,
    );
    has wantarray => (
        is => 'ro',
        required => 1,
    );
    has evaltext => (
        is => 'ro',
        required => 1,
    );
    has is_require => (
        is => 'ro',
        required => 1,
    );
    has hints => (
        is => 'ro',
        required => 1,
    );
    has bitmask => (
        is => 'ro',
        required => 1,
    );
    has hinthash => (
	is => 'ro',
	required => 1,
    );
}
