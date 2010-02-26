use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Llama',
    license             => 'perl',
    dist_author         => q{James Laver <cpan@jameslaver.com>},
    dist_version_from   => 'lib/Llama.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Llama-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
