package Import::AtUse;
use strict;
use warnings;

our $VERSION = '0.001000';
$VERSION =~ tr/_//d;

sub _call_method {
  my $method = shift;
  my $level = 0;
  while (my @caller = caller(++$level)) {
    if($caller[3] =~ /::BEGIN\z/) {
      my ($package, $file, $line) = caller($level - 1);

      my $code = sprintf <<'END_CODE', $package, $line, $file, $method;
package %s;
sub {
  my $module = shift;
#line %d "%s"
  $module->%s(@_);
};
END_CODE
      my $trampoline = eval $code
        or die "Failed to build dispatch sub to $method for $package: $@";
      return &$trampoline;
    }
  }
  die "Unable to find compiling code";
}

sub import::at_use   { _call_method(import => @_) }
sub unimport::at_use { _call_method(unimport => @_) }
sub VERSION::at_use  { _call_method(VERSION => @_) }

1;
__END__

=head1 NAME

Import::AtUse - C<import> package at currently compiling code

=head1 SYNOPSIS

  package My::MultiExporter;

  use Import::AtUse;

  # simple
  sub import {
    Thing1->import::at_use;
  }

  # multiple
  sub import {
    Thing1->import::at_use;
    Thing2->import::at_use(qw(import arguments));
  }

People wanting to re-export your module do not need to use Import::AtUse,
as it will always find the currently compiling code.

Note: You do B<not> need to make any changes to Thing1 to be able to call
C<import::at_use> on it. This is a global method, and is callable on any
package (and in fact on any object as well, although it's rarer that you'd
want to do that).

=head1 DESCRIPTION

Writing exporters is a pain. Some use L<Exporter>, some use L<Sub::Exporter>,
some use L<Moose::Exporter>, some use L<Exporter::Declare> ... and some things
are pragmas.

Exporting on someone else's behalf is harder.  The exporters don't provide a
consistent API for this, and pragmas need to have their import method called
directly (not in an C<eval "">), since they affect the current unit of
compilation.

C<Import::AtUse> provides global methods to make this painless.

The "currently compiling code" is generally the location of the closest B<use>
statement. It may also be the closest C<BEGIN> block.

=head1 METHODS

=head2 $package->import::at_use( @arguments );

A global method, callable on any package. Imports the given package to the
code currently being compiled. C<@arguments> are passed along to the package's
import method.

=head2 $package->unimport::at_use( @arguments );

Equivalent to C<import::at_use>, but dispatches to C<$package>'s C<unimport>
method instead of C<import>.

=head2 $package->VERSION::at_use( @arguments );

Equivalent to C<import::at_use>, but dispatches to C<$package>'s C<VERSION>
method instead of C<import>.

=head1 WHY USE THIS MODULE

...

=head1 SEE ALSO

=over 4

=item L<Import::Into>

B<Import::Into> is meant to solve roughly the same problem as this module, but
requires you to specify the level or target package to import into. This can
lead to inconsistencies, because the imported module may be doing exports as
well as applying lexical effects. If the level or package does not match the
currently compiling level, this will be inconsistent. B<Import::AtUse> fixes
this by always exporting to the same location that the lexical effect will
apply. B<Import::Into> also loads the module to be imported. It is the opinion
of the author of B<Import::AtUse> that this is a mistake, and the only
difference between an B<import> and B<import::at_use> call should be the
apparent calling location.

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 COPYRIGHT

Copyright (c) 2022 the Import::AtUse L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
