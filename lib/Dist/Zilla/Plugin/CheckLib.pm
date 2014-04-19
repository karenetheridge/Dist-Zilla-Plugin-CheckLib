use strict;
use warnings;
package Dist::Zilla::Plugin::CheckLib;
# ABSTRACT: ...
# vim: set ts=8 sw=4 tw=78 et :

use Moose;
with 'Dist::Zilla::Role::...';

use namespace::autoclean;



__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    [CheckLib]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that...

=head1 CONFIGURATION OPTIONS

=head2 C<foo>

...

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-CheckLib>
(or L<bug-Dist-Zilla-Plugin-CheckLib@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-CheckLib@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 ACKNOWLEDGEMENTS

...

=head1 SEE ALSO

=begin :list

* L<foo>

=end :list

=cut
