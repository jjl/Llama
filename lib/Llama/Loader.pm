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

       subtype LlStrArrayRef
           => as 'ArrayRef[Str']
           => where { 1 };
       coerce LlStrArrayRef
           => from 'Str',
           => via { [$_] };

   }


    # Namespace to load from, eg. MyApp::Plugins
    has _namespaces => (
        traits => ['Array'],
        isa => 'LlStrArrayRef',
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
        isa => 'LlStrArrayRef',
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
        isa => 'LlStrArrayRef',
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
        isa => 'LlStrArrayRef',
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
        isa => 'ArrayRef[RegexpRef]',
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
        isa => 'ArrayRef[CodeRef]',
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
__END__

=head1 NAME

Llama::Loader - Load files and plugins with ludicrous customisability

=head1 SYNOPSIS

 use Llama::Loader;
 use Data::Dump 'pp';
 # Note that ALL of these are optional parameters
 my $loader = Llama::Loader->new(
   namespaces => 'MyApp::Plugins', # Load things under this namespace
   paths => '/strange/path/hierarchy', #Load from here instead of @INC
   parts => 'dev', # For each path, append 'dev' before trying to load
   exhaust_parts => 0, # See discussion below
   use_part_tips => 1, # See discussion below
   create => 1, # Instantiate and return objects rather than names
   create_args => [qw(foo bar baz)], # arguments to pass to constructors
   exclude => [
       qw(MyApp::Plugins::Foo MyApp::Plugins::Bar), # Things by name
       qr/:[a-z]+$/, # Things by regexp (in this case where the last atom is a lowercase word)
       sub { ... }, # Things by callback
   ]
 );
 # And pretty print the list of plugins
 pp([$loader->load_plugins]);

=head1 CONSTRUCTOR PARAMETERS

All of these are setters for the appropriate attributes

=head2 namespaces :: ArrayRef[Str] | <Str> <- default: caller namespace
=head2 paths :: ArrayRef[Str] | <Str> <- default: @INC
=head2 parts :: ArrayRef[Str] | <Str> <- default: []
=head2 exhaust_parts :: Bool <- default: 0
=head2 use_part_tips :: Bool <- default: 0
=head2 create :: Bool <- default: 0
=head2 create_args :: ArrayRef <- default: []
=head2 exclude :: ArrayRef[ RegexpRef | CodeRef | Str ] | <RegexpRef> | <CodeRef> | <Str> <- default: []

=head1 DATA MEMBERS

You can adjust some of the read only members via METHODS.

=head2 namespaces :: ArrayRef[Str] <- ro

List of namespaces to search in

=head2 paths :: ArrayRef[Str] <- ro

A list of paths to try loading from. If given, does not include @INC unless specified.

=head2 parts :: ArrayRef[Str] <- ro

A list of parts to append onto each path before attempting load.

Given paths = [qw(/foo /bar)] and parts of [qw(baz quux)], it will attempt to load as follows:

/foo/baz
/foo/quux
/bar/baz
/bar/quux

=head2 exhaust_parts :: Bool <- rw

Given the above code, if you wanted to load quux::garble, which resides in /foo/quux/garble,
 given a part of 'quux', it would fail to load. This will exhaustively attempt to load modules
from the last atom of their name upwards. Enabling it has performance penalties.

=head2 use_part_tips :: Bool <- rw

Similar to the above, but only attempts to load for the last atom.

=head2 create :: Bool <- rw

Normally, load_plugins will return a list of package names. Tipping this will cause it to instantiate the objects and return them instead.

=head2 create_args :: ArrayRef <- rw

If create is enabled, these args will be passed along

=head2 exclude :: ArrayRef[ RegexpRef | CodeRef | Str ] | <RegexpRef> | <CodeRef> | <Str> <- rw

Allows you to specify complex exclusion rules for modules. For each item, if it matches a string or regexp, it is discarded. If you supplied a coderef, it will be called back with ($packagename,$filepath) and will be discarded if you return a false value.

=head1 METHODS

=head2 add_ns :: (@Str) => ()

Adds one or more namespaces to the library search path

=head2 clear_ns :: () => ()

Clears the library search path of namespaces. Note that this does not restore it to containing the calling namespace.

=head2 add_path :: (@Str) => ()

Adds one or more paths to the file search path.

=head2 add_paths :: (@Str) => ()

Adds one or more paths to the file search path.

=head2 clear_paths :: () => ()

Clears the file search path. Note that this does not restore it to containing @INC.

=head2 add_part :: (@Str) => ()

Adds one or more path parts.

=head2 add_parts :: (@Str) => ()

Adds one or more path parts.

=head2 clear_parts :: () => ()

Clears all path parts.

=head2 load_plugins :: () => ( ArrayRef[ Obj ] | ArrayRef [ Str ] )

If C<create> is set, returns a list of object references, else a list of strings that are loadable plugins.

=head2 load_plugin :: (Str,Str?) => ( ArrayRef[ Obj ] | ArrayRef [ Str ] )

Attempts to load a single named plugin, taking into account any funky paths

=head1 COPYRIGHT AND LICENCE

Copyright 2010 James Laver <cpan at jameslaver dot com>

This file is licenced under the same terms as perl itself.

=head1 ACKNOWLEDGEMENTS

Thanks to Simon Wistow for Module::Pluggable, which I see as having made
the mistakes I can learn from ;)

=head1 SEE ALSO

L<Llama> - Useful utilities for frameworks

=head1 NOTE ON POD

This uses custom POD formatting that ought to be standardised. See L<http://jameslaver.com/pod-standards.txt> for more information.

=cut
