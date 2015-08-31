#!/usr/bin/perl
use warnings;
use strict; 

use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(dirname abs_path $0) . '/';

package MyParser;
use Carp;
use AstBuilder;
use Verilog::Parser;
use base qw(Verilog::Parser);

# parse, parse_file, etc are inherited from Verilog::Parser
sub new {
    my $class = shift;
    #print "Class $class\n";
    my $self = $class->SUPER::new();
    $self->{_astBuild} = shift;
    bless $self, $class;
    return $self;
}

sub attribute {
    my $self = shift;
    my $token = shift;
    #printf "%s ATTR\n", $token;
    $self->{_astBuild}->accept_token($token, 'ATTRIBUTE', $self->line());
}

sub comment { 
    my $self = shift;
    my $token = shift;
    #printf "%s\n", $token;
    $self->{_astBuild}->accept_token($token, 'COMMENT', $self->line());
}

sub string {
    my $self = shift;
    my $token = shift;
    #printf "%s\n", $token;
    $self->{_astBuild}->accept_token($token, 'string', $self->line());
}

sub operator {
    my $self = shift;
    my $token = shift;
    #printf "%s OPERATOR \n", $token;
    $self->{_astBuild}->accept_token($token, 'OPERATOR', $self->line());
}

sub preproc {
    my $self = shift;
    my $token = shift;
    #printf "%s PREPROC\n", $token;
    $self->{_astBuild}->accept_token($token, 'PREPROC', $self->line());
}
sub number {
    my $self = shift;
    my $token = shift;
    #printf "%s\n", $token;
    $self->{_astBuild}->accept_token($token, 'NUMBER', $self->line());
}

sub sysfunc {
   my $self = shift;
    my $token = shift;
    #printf "%s SYSFUNC\n", $token;
    $self->{_astBuild}->accept_token($token, 'SYSFUNC', $self->line());
}

sub symbol {
    my $self = shift;
    my $token = shift;
    $self->{symbols}{$token}++;
    #printf "%s\n", $token;
    $self->{_astBuild}->accept_token($token, 'SYMBOL', $self->line());
}

sub keyword {
    my $self = shift;
    my $token = shift;
    #printf "%s\n", $token;
    $self->{_astBuild}->accept_token($token, 'KEYWORD', $self->line());
}

sub report {
    my $self = shift;
    foreach my $sym (sort keys %{$self->{symbols}}) {
	printf "Symbol %-30s occurs %4d times",
	$sym, $self->{symbols}{$sym};
    }
}

sub parse_file {
    # Read a file and parse
    my $self = shift;
    my $filename = shift;

    my $fh = new IO::File;
    $fh->open($filename) or croak "Unable to open file ", $filename;
    $self->reset();
    $self->filename($filename);
    $self->lineno(1);
    while (defined(my $line = $fh->getline())) {
        #$self->_astBuild->add_line($line, $self->line());
	$self->parse ($line);
    }
    $self->eof;
    $fh->close;
    return $self;
}

package main;
use AstBuilder;
use Carp;

test();

my $ast_build = AstBuilder->new();
my $parser = MyParser->new($ast_build);
$parser->parse_file (shift);
printf "Num seq assign: %d\n", $ast_build->{_num_assign}; 
#$parser->report();

sub test{
    my $ast = AstBuilder->new();
    my @test_result = $ast->parse_num('3\'b001');
    if($test_result[0] != 3 && $test_result[1] != oct('0b001') && $test_result[2] ne 'BIN'){
	croak "test 1 failed";
    }
    @test_result = $ast->parse_num('4\'hA');
    if($test_result[0] != 4 && $test_result[1] != oct('0xA') && $test_result[2] ne 'HEX'){
	croak "test 2 failed";
    } 
    @test_result = $ast->parse_num('6\'o77');
    if($test_result[0] != 6 && $test_result[1] != oct('0o77') && $test_result[2] ne 'OCT'){
	croak "test 3 failed";
    }
    @test_result =  $ast->parse_num('12');
    if($test_result[0] != -1 && $test_result[1] != oct('12') && $test_result[2] ne 'DEC'){
	croak "test 4 failed";
    }
}
