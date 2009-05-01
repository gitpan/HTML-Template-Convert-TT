package _Auxiliary;

use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(test);

use Test::More 'no_plan';
use HTML::Template::Convert::TT 'convert';

sub test {
	SKIP: {
			eval { require HTML::Template; };
			skip 'HTML::Template is not installed' if $@;
			eval { require Template; };
			skip 'TemplateToolkit is not installed' if $@;

			use HTML::Template;
			use Template;
			
			my ($fname, $data) = @_;
			my $tmpl = HTML::Template->new(filename => $fname);
			$tmpl->param($data);
			my $tt = Template->new;
			my $text = convert $fname;
			my $tt_output;
			$tt->process(\$text, $data, \$tt_output);
			is  $tt_output, $tmpl->output;
	}
}


1;


