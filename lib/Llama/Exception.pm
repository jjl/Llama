use MooseX::Declare;

class Llama::Exception {
	use Llama::Exception::Trace;
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
		Llama::Exception::Trace->new;
	}
}
__END__