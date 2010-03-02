use MooseX::Declare;

class Llama::Exception {

    use Llama::Exception::Trace;

    has skip_levels => (
        isa => 'Int',
	is => 'ro',
        default => 0,
    );
    has errno => (
        isa => 'Int',
        is => 'ro',
        required => 0,
    );
    has code => (
        isa => 'Str',
        is => 'ro',
        required => 0,
    );
    has message => (
        isa => 'Str',
        is => 'ro',
        required => 0,
    );
    has trace => (
        isa => 'Llama::Exception::Trace',
        is => 'ro',
        builder => '_build_trace',
    );

    method _build_trace {
        Llama::Exception::Trace->new(
            skip => $self->_skip(),
        );
    }

}
__END__
