use strict;
use warnings;
package Dist::Zilla::Plugin::CheckLib;
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Require that your distribution has a particular library available
# KEYWORDS: distribution installation require compiler library header resource

our $VERSION = '0.008';

use Moose;
with
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::InstallTool',
    'Dist::Zilla::Role::PrereqSource',
;
use Scalar::Util 'blessed';
use namespace::autoclean;

my @list_options = qw(header incpath lib libpath);
sub mvp_multivalue_args { @list_options }

has $_ => (
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [] },
    traits => ['Array'],
    handles => { $_ => 'sort' },
) foreach @list_options;

my @string_options = qw(INC LIBS debug);
has \@string_options => (
    is => 'ro', isa => 'Str',
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        ( map +($_ => [ $self->$_ ]), @list_options ),
        ( map +($_ => $self->$_), @string_options ),
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };

    return $config;
};

sub register_prereqs
{
    my $self = shift;
    $self->zilla->register_prereqs(
        {
          phase => 'configure',
          type  => 'requires',
        },
        'Devel::CheckLib' => '0.9',
    );
}

my %files;
sub munge_files
{
    my $self = shift;

    my @mfpl = grep +($_->name eq 'Makefile.PL' or $_->name eq 'Build.PL'), @{ $self->zilla->files };
    for my $mfpl (@mfpl)
    {
        $self->log_debug([ 'munging %s in file gatherer phase', $mfpl->name ]);
        $files{$mfpl->name} = $mfpl;
        $self->_munge_file($mfpl);
    }
    return;
}

# XXX - this should really be a separate phase that runs after InstallTool -
# until then, all we can do is die if we are run too soon
sub setup_installer
{
    my $self = shift;

    my @mfpl = grep +($_->name eq 'Makefile.PL' or $_->name eq 'Build.PL'), @{ $self->zilla->files };

    $self->log_fatal('No Makefile.PL or Build.PL was found. [CheckLib] should appear in dist.ini after [MakeMaker] or variant!') unless @mfpl;

    for my $mfpl (@mfpl)
    {
        next if exists $files{$mfpl->name};
        $self->log_debug([ 'munging %s in setup_installer phase', $mfpl->name ]);
        $self->_munge_file($mfpl);
    }
    return;
}

sub _munge_file
{
    my ($self, $file) = @_;

    my $orig_content = $file->content;
    $self->log_fatal([ 'could not find position in %s to modify!', $file->name ])
        if not $orig_content =~ m/use strict;\nuse warnings;\n\n/g;

    my $pos = pos($orig_content);

    # build a list of tuples: field name => string
    my @options = (
        (map {
            my @stuff = map '\''.$_.'\'', $self->$_;
            @stuff
                ? [ $_ => @stuff > 1 ? ('[ ' . join(', ', @stuff) . ' ]') : $stuff[0] ]
                : ()
        } @list_options),
        (map {
            defined $self->$_
                ? [ $_ => '\'' . $self->$_ . '\'' ]
                : ()
        } @string_options),
    );

    $file->content(
        substr($orig_content, 0, $pos)
        . "# inserted by " . blessed($self) . ' ' . $self->VERSION . "\n"
        . "use Devel::CheckLib;\n"
        . "check_lib_or_exit(\n"
        . join('',
                map '    '.$_->[0].' => '.$_->[1].",\n", @options
            )
        . ");\n\n"
        . substr($orig_content, $pos)
    );
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    [CheckLib]
    lib = jpeg
    header = jpeglib.h

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that modifies the F<Makefile.PL> or
F<Build.PL> in your distribution to contain a L<Devel::CheckLib> call, that
asserts that a particular library and/or header is available.  If it is not
available, the program exits with a status of zero, which on a
L<CPAN Testers|cpantesters.org> machine will result in a NA result.

=for Pod::Coverage mvp_multivalue_args register_prereqs munge_files setup_installer

=head1 CONFIGURATION OPTIONS

All options are as documented in L<Devel::CheckLib>:

=head2 C<lib>

A string with the name of a single library name. Can be used more than once.
Depending on the compiler found, library names will be fed to the compiler
either as C<-l> arguments or as C<.lib> file names. (e.g. C<-ljpeg> or
C<jpeg.lib>)

=head2 C<libpath>

Additional path to search for libraries. Can be used more than once.

=head2 C<LIBS>

A L<ExtUtils::MakeMaker>-style space-separated list of libraries (each preceded by C<-l>) and directories (preceded by C<-L>).

=head2 C<debug>

If true, emit information during processing that can be used for debugging.
B<Note>: as this is an arbitrary string that is inserted directly into
F<Makefile.PL> or F<Build.PL>, this can be any arbitrary expression,
for example:

    [CheckLib]
    debug = $ENV{AUTOMATED_TESTING} || $^O eq 'MSWin32'

=head2 C<header>

The name of a single header file name. Can be used more than once.

=head2 C<incpath>

An additional path to search for headers. Can be used more than once.

=head2 C<INC>

=for stopwords incpaths

A L<ExtUtils::MakeMaker>-style space-separated list of incpaths, each preceded by C<-I>.

=head1 SEE ALSO

=for :list
* L<Devel::CheckLib>
* L<Devel::AssertOS> and L<Dist::Zilla::Plugin::AssertOS>
* L<Devel::CheckBin> and L<Dist::Zilla::Plugin::CheckBin>

=cut
