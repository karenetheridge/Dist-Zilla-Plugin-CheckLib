use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Fatal;

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'MakeMaker' => ],
                [ 'CheckLib' => {
                        lib => [ qw(iconv jpeg) ],
                        header => 'jpeglib.h',
                        libpath => 'additional_path',
                        debug => 0,
                        LIBS => '-lfoo -lbar -Lkablammo',
                        incpath => [ qw(inc1 inc2 inc3) ],
                    },
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

is(
    exception { $tzil->build },
    undef,
    'nothing exploded',
);

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child('Makefile.PL');
ok(-e $file, 'Makefile.PL created');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated file');

my $version = Dist::Zilla::Plugin::CheckLib->VERSION || '<self>';

my $pattern = <<PATTERN;
use strict;
use warnings;

# inserted by Dist::Zilla::Plugin::CheckLib $version
use Devel::CheckLib;
check_lib_or_exit(
    header => 'jpeglib.h',
    incpath => [ 'inc1', 'inc2', 'inc3' ],
    lib => [ 'iconv', 'jpeg' ],
    libpath => 'additional_path',
    LIBS => '-lfoo -lbar -Lkablammo',
    debug => '0',
);
PATTERN

like(
    $content,
    qr/^\Q$pattern\E$/m,
    'code inserted into Makefile.PL',
);

done_testing;
