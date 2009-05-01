package HTML::Template::Convert::TT;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HTML::Template::Convert::TT ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	convert	
);

our $VERSION = '0.02';


sub convert {
	my $source;
	my $fname = shift;
	if(ref($fname)) {
		$source = $fname;
	}
	else {
		open FH, $fname or die $!;
		# read whole file
		undef $/;
		$source = <FH>;
	}
	my @chunk = split /(?=<)/, $source;
	close FH;
	my $text;
	my ($tag, $test);
	my @stack;
	my $it = 0;
	my %push= ( 
		VAR => 0,
		LOOP => 1,
		INCLUDE => 0,
		IF => 1,
		ELSE => 0,
		UNLESS => 1
	);
	for(@chunk) {
		my ($name, $default, %escape);
		if (/^<
			(?:!--\s*)?
			(?:
				(?i:TMPL_
					(VAR|LOOP|INCLUDE|IF|UNLESS|ELSE) # $1
				)
				\s*
			)

			(.*?) # parameters

			(?:--)?>                    
			(.*) # $3
			/sx)  {
				my ($tag, $rest) = (uc $1, $3);
				$_ = $2;
				pos = 0;
				while (/\G
					(?i:
						\b
						(DEFAULT|NAME|ESCAPE)
						\s*=\s*
						
					)?
					(?:
						"([^"]+)"
						|
						'([^']+)'
						|
						([^\s]+)
					)
					\s*
					/xgc) 
				{
					my $val = defined $2? $2: defined $3? $3: $4;
					chomp $val;
					if (defined $1 and uc $1 ne 'NAME') {
						if(uc $1 eq 'DEFAULT') {
							die "DEFAULT parameter has already defined" if defined $default;
							$default = $val; 
						}
						else {
							die "Invalid ESCAPE parameter" unless
								$val =~ /0|1|html|url|js|none/i;
							$escape{lc $val} = 1;
						}
					}
					else {
						die "NAME parameter has already defined" if defined $name;
						$name = $val;
					}
				}
				die "Invalid parameter syntax($1)". pos if /\G(.+)/g;
				push @stack, $tag if $push{$tag};
				#$name = "i$it.$name" if $it;
				if ($tag eq 'VAR') {
					$text .= "[% DEFAULT $name = '$default' %]"
						if defined $default;

					my $filter = '';
					$filter .= " | html | replace('\\\'', '\&#39;')" 
						if exists $escape{html} or exists $escape{1};
					$filter .= " | uri" if exists $escape{url}; 
					$filter .= 
						" | replace('\\'', '\\\\\\'')".
						" | replace('\"', '\\\"')".
						" | replace('\\n', '\\\\n')".
						" | replace('\\r', '\\\\r')"
						if exists $escape{js};
					$text .= "[% $name$filter %]"
						if $name or
							die "Empty 'NAME' parameter";
				}
				elsif ($tag eq 'LOOP') {
					++$it;
					$text .= "[% FOREACH $name %]" 
						if $name or
							die "Empty 'NAME' parameter";
				}
				elsif ($tag eq 'INCLUDE') {
					$text .= convert($name)
						if $name or die "Empty 'NAME' parameter";
				}
				elsif ($tag eq 'IF' or $tag eq 'UNLESS') {
					$text .= "[% $tag $name %]" if $name or
						die "Empty 'NAME' parameter";
				}
				else { # ELSE TAG
					die "ELSE tag without IF/UNLESS first"
						unless 
							@stack and 
							$stack[$#stack] =~ /IF|UNLESS/;
					$text .= '[% ELSE %]';

				}
				$text .= $rest;
		}
		elsif (/^<(?:!--\s*)?\/TMPL_(LOOP|IF|UNLESS)\s*(?:--)?>(.*)/si) {
			$tag = uc $1;
			die "/TMPL_$tag tag without TMPL_$tag first" 
				unless @stack;
			die "Unexpected /TMPL_$tag tag " 
				unless $tag = pop @stack;
			--$it if $tag eq 'LOOP';
			$text .= "[% END %]$2";
		}
		else {
			die "Syntax error in TMPL_* tag" 
				if /^<(?:!--\s*)\/?TMPL_/i;
			$text .= $_;
		}
	}

	return $text;
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

HTML::Template::Convert::TT - Perl extension for blah blah blah

=head1 SYNOPSIS

  use HTML::Template::Convert::TT;
  use Template;
  
  my $foo-text = 'Hello, <TMPL_VAR wonderfull> world!';
  my $tt = Template->new;
  $tt->process(\$foo-text, {wonderfull->template});

=head1 DESCRIPTION

Translate HTML::Template template into Template toolkit syntax

Blah blah blah.

=head2 EXPORT

convert

=head1 SEE ALSO

Web site: http://code.google.com/p/html-template-convert/
SVN: 
	 Non-members may check out a read-only working copy anonymously over HTTP.
	 svn checkout http://html-template-convert.googlecode.com/svn/trunk/ html-template-convert-read-only

=head1 AUTHOR

A. D. Solovets, E<lt>asolovets@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by A. D. Solovets

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
