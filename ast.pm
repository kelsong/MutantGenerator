#!/usr/bin/perl
use strict;
use warnings;

package AstType;
use constant {
    EXPR => 'expr',
    UNARYOP => 'un_op',
    BINARYOP => 'bin_op',
    TRINARYOP => 'tri_op',
    CONST => 'const',
    NUMBER => 'num'
};

package AstExpr;
sub new{
    my $class = shift;
    my $self = {};
    $self->_fileline = shift;
    $self->_is_mutation = shift;
    bless $self, $class;
    return $self;
}

sub type {
    return AstType::EXPR;
}

#baseline empty, just here to know we must override
sub mutate {
}

package AstBinaryOp;
our @ISA = qw(AstExpr);

sub type {
    return AstType::BINARYOP;
}

package AstUnaryOp;
our @ISA = qw(AstExpr);

sub type {
    return AstType::UNARYOP; 
}

package AstTriOp;
our @ISA = qw(AstExpr);

sub type {
    return AstType::TRINARYOP;
}

package AstNum;
our @ISA = qw(AstExpr);

sub type {
    return AstType::NUMBER;
}

package AstConst;
our @ISA = qw(AstExpr);

sub type {
    return AstType::CONST;
}

package AstBuilder;
use Switch;
#this is the primary worker. It builds the AST and enforces rules of recognition. All callbacks pass their tokens up to the builder. 
#base rules 
# if statements
# switch statement
# assignment statements
# wire statements
# assign statements
# preprocessor directives

use constant {
    START => 0,
    IF_KEY_FOUND => 1,
    IF_EXPR => 2,
    SWITCH_KEY => 3,
    SWITCH_EXPR => 4,
    ASSIGN_SYMBOL => 5,
    ASSIGN_EXPR => 6,
    WIRE_SYMBOL => 7,
    WIRE_EXPR => 8,
    SEQ_ASSIGN => 9,
    SEQ_ASSIGN_EXPR => 10,
    TERM => 11,
    OTHER => 12,
    AlWAYS => 13,
};

sub new {
    my $class = shift;
    my $self = {
	_state => START,
        mutation_gen => shift,
	expr_lines => { }
    };
    bless $self, $class;
    return $self;
}

sub add_line {
    my $self = shift;
    my $line = shift;
    my $lineno = shift;
    $self->{expr_lines}->{$lineno} = $line;
}

sub clear_lines {
    my $self = shift;
    for (keys %{$self->expr_lines}) { delete $self->{expr_lines}->{$_};};
    $self->expr_lines = {};
}
#manages the expression recognition state machine
sub accept_token {
    my $self = shift;
    my $token = shift;
    my $token_type = shift;
    my $symbol_found = 0;

    switch ($self->_state){
	case START {
	    #6 edges: S->if key, S->switch Key, S->Assign Key, S->wire key, S->Seq assign
	    if($token_type == 'KEYWORD') {
		#if
		if($token == 'if'){
		    #create ASTNODE
		    $self->_state = IF_KEY_FOUND; 
		}
		#switch
		elsif($token == 'switch') {
		    $self->_state = SWITCH_KEY;
		}
		#assign
		elsif($token == 'assign') {
		    $self->_state = ASSIGN_SYMBOL;
		}
		#wire
		elsif($token == 'wire'){
		    $self->_state = WIRE_SYMBOL;
		} 
		else {
		    if($token != 'begin' && $token != 'end' && $token != 'else'){
			$self->_state = OTHER;
		    }
		}
	    }

	    if($token_type == 'SYMBOL') { #maybe not... this could fail...
		#seq assign
		$self->_state = SEQ_ASSIGN;
	    }

	    if($token_type == 'EOF'){
		$self->_state = TERM;
	    }
	    
	    $self->_state = START;
	}
	case IF_KEY_FOUND {
	    #accepts a "(" and then moves to expression parsing
	    if($token == '(') {
		$self->_state = IF_EXPR; 
	    }
	}
        case IF_EXPR {
	    #grabs the ")"
	    if($token == ')'){
		printf "FOUND IF STATEMENT\n";
		$self->_state = START;
	    }
	}
	case SWITCH_KEY {
	    # accepts the "("
	    if($token == '('){
		$self->_state = SWITCH_EXPR;
	    }
	}
	case SWITCH_EXPR {
	    #gets the controlling variable and closing ")"
	    if($token == ')'){
		printf "FOUND SWITCH STATEMENT\n";
		$self->_state = START;
	    }
	}
	case ASSIGN_SYMBOL {
	    #this state grabs the symbol and operator.
	    if($token_type == 'SYMBOL'){
		$symbol_found = 1;
		$self->_state = ASSIGN_SYMBOL;
	    }
	    elsif($token == '=' && $symbol_found == 1){
		$self->_state = ASSIGN_EXPR;
	    }
	}
	case ASSIGN_EXPR {
	    #grabs the assigning expression
	    if($token_type == 'OPERATOR'){
		if($token == ';'){
		    $self->_state = START;
		    $symbol_found = 0;
		}
	    }
	}
	case WIRE_SYMBOL {
	    #grabs the symbol and assignment operator
	    if($token_type == 'SYMBOL'){
		$symbol_found = 1;
		$self->_state = ASSIGN_SYMBOL;
	    }
	    elsif($token == '=' && $symbol_found == 1){
		$self->_state = ASSIGN_EXPR;
	    }
	    
	}
	case WIRE_EXPR {
	    #grabs the assigning wire expression
	    if($token_type == 'OPERATOR'){
		if($token == ';'){
		    printf "FOUND WIRE STATEMENT\n";
		    $self->_state = START;
		    $symbol_found = 0;
		}
	    }
	}
	case SEQ_ASSIGN {
	    #expects the assignment operator
	     if($token_type == 'OPERATOR'){
		 if($token == '<='){
		     $self->_state = SEQ_ASSIGN_EXPR;
		 }
	     }
	}
	case SEQ_ASSIGN_EXPR {
	    #gets the assigning expression and the terminating condition
	    if($token_type == 'OPERATOR'){
		 if($token == '<='){
		     printf "FOUND SEQ NON-BLOCKING ASSIGN STATEMENT\n";
		     $self->_state = START;
		 }
	     }
	}
	case TERM {
	    #eof state.
	}
	case OTHER {
	    #skip until ;
	    if($token_type == 'OPERATOR'){
		 if($token == ';'){
		     $self->_state = START;
		 }
	    }
	}
	#case ALWAYS {
	#    #wait until ), skip sensitivity list
	#    if($token == ')'){
	#	$self->_state = START; 
	#    }
	#}
	else { #error states
	}
    }
}
