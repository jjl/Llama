use MooseX::Declare;

class Llama::Loader {

   use Llama::Exception;

   {
       use Moose::Util::TypeConstraints;
       type LlFilter
           => where {
               ref $_ eq 'ARRAY' and
               !grep { ref $_ and ref $_ ne 'CODE' and ref $_ ne 'Regexp' }
       };
       coerce LlFilter
           => from 'Str'
           => via { [$_] };
       coerce LlFilter
           => from 'CodeRef'
           => via { [$_] };
       coerce LlFilter
           => from 'RegexpRef'
           => via { [$_] };
   }


    # Namespace to load from, eg. MyApp::Plugins
    has _namespaces => (
        traits => ['Array'],
        isa => 'ArrayRef[Str]',
        is => 'ro',
        init_arg => 'namespaces',
        # FIXME : Replace me with something robust and not ugly
        builder => '_build_namespaces',
        handles => {
            namespaces => 'elements',
            add_ns => 'push',
            clear_ns => 'clear',
        },
    );

    # List of all paths it will attempt to load from
    has _paths => (
        traits => ['Array'],
        isa => 'ArrayRef[Str]',
        is => 'ro',
        init_arg => 'paths',
        default => sub { [@INC] },
        handles => {
            paths => 'elements',
            add_path => 'push',
            add_paths => 'push',
            clear_paths => 'clear',
        },
    );

    # Path parts. For each item in the search path, try each of these to load the module.
    has _path_parts => (
        traits => ['Array'],
        isa => 'Str',
        is => 'ro',
        init_arg => 'parts',
        default => sub { [] },
        handles => {
            parts => 'elements',
            add_part => 'push',
            add_parts => 'push',
            clear_parts => 'clear',
        },
    );

    # Enabling this will cause extra overhead
    has exhaust_parts => (
        isa => 'Bool',
        is => 'rw'
        default => 0,
    );

    # This takes care of the original planned dodgy layout for Alpaca. See docs
    has use_part_tips => (
        isa => 'Bool',
        is => 'rw',
        default => 0,
    );

    # Whether to instantiate the relevant objects
    has create => (
        isa => 'Bool',
        is => 'rw',
        default => 0,
    );

    # Args to pass along during creation
    has create_args => (
        isa => 'ArrayRef',
        is => 'rw',
        default => sub { [] },
    );

    # The trigger on this sorts it out into individual parts so at least it's manageable
    has exclude => (
        isa => 'Maybe[LlFilter]',
        is => 'rw',
        default => sub { [] },
        trigger => \&_update_exclusions,
    );

    # Name exclusions
    has _exclude_names => (
        traits => ['Array'],
        isa => 'ArrayRef[Str]',
        is => 'rw',
        lazy_build => 1,
        handles => {
            '_excluded_names' => 'elements',
            '_add_exclude_names' => 'push',
            '_clear_exclude_names' => 'clear',
        },
    );

    # Regex exclusions
    has _exclude_regexrefs => (
        traits => ['Array'],
        isa => 'ArrayRef[Str]',
        is => 'rw',
        lazy_build => 1,
        handles => {
            '_excluded_regexrefs' => 'elements',
            '_add_exclude_regexrefs' => 'push',
            '_clear_exclude_regexrefs' => 'clear',
        },
    );

    # Callback exclusions
    has _exclude_coderefs => (
        traits => ['Array'],
        isa => 'ArrayRef[Str]',
        is => 'rw',
        lazy_build => 1,
        handles => {
            '_excluded_coderefs' => 'elements',
            '_add_exclude_coderefs' => 'push',
            '_clear_exclude_coderefs' => 'clear',
        },
    );

    # Seperate exclusions into the different pots
    method _update_exclusions($exclusions) {
        foreach my $exclusion (@$exclusions) {
            if (ref($exclusion)) {
                if (ref($exclusion) eq 'CODE') {
                    $self->_add_exclude_coderefs($exclusion);
                } elsif (ref($exclusion) eq 'Regexp') {
                    $self->_add_exclude_regexrefs($exclusion);
                } else {
                    die(Llama::Exception->new(
                            code => 'invalid_type',
                            message => "Shouldn't be able to get here. Invalid type: " . ref($exclusion),
                    ));
                }
            } else {
                $self->_add_exclude_names($exclusion);
            }
        }
    }

    method _
}
