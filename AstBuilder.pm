#!/usr/bin/perl
use strict;
use warnings;
use 5.014;

package AstType;
use Switch;

use constant {
    EXPR => 'expr',
    UNARYOP => 'un_op',
    BINARYOP => 'bin_op',
    TRINARYOP => 'tri_op',
    CONST => 'const',
    NUMBER => 'num',
    SYMBOL => 'sym',
    STMT => 'stmt',
};

sub getOpType {
    my $op_token = shift;
    switch($op_token){
	#arithmetic operators
	case '+' {
	    return 'BIOP';
	} case '-' {
	    return 'BI-UNI';
	} case '*' {
	    return 'BIOP';
	} case '/' {
	    return 'BIOP';
	} case '%' {
	    return 'BIOP';
	}
	#relational operators
	case '<' {
	    return 'BIOP';
	} case '<=' {
	    return 'BIOP';
	} case '>' {
	    return 'BIOP';
	} case '>='{
	    return 'BIOP';
	}
	#equality operators
	case '==' {
	    return 'BIOP';
	} case '!=' {
	    return 'BIOP';
	} case '===' {
	    return 'BIOP';
	} case '!==' {
	    return 'BIOP';
	}
	#logical operators
	case "!" {
	    return 'UNIOP';
	} case "&&" {
	    return 'BIOP';
	} case "||" {
	    return 'BIOP';
	} 
        #bitwise operators, Don't handle reduction ops
	case '~' {
	    return 'UNIOP';
	} case '&' {
	    return 'BIOP';
	} case '|' {
	    return 'BIOP';
	} case '^' {
	    return 'BIOP';
	} case '^~' {
	    return 'BIOP';
	} case '~^' {
	    return 'BIOP';
	}
	#shift
	case '<<' {
	    return 'BIOP';
	} case '>>' {
	    return 'BIOP';
	}
	#select operator
	case "[" { #could be range select or just select
	    return 'BI-TRI';
	} case ':' {
	    return 'BI-TRI';
	} case ']' {
	    return 'BI-TRI';
	} case "(" {
	    return 'UNIOP';
	} case ")" {
	    return 'UNIOP';
	} case '?' {
	    return 'TRIOP';
	}
    }
}

package AstExpr;
sub new{
    my $class = shift;
    my $self = {};
    $self->{_fileline} = shift;
    $self->{_is_mutation} = shift;
    $self->{_next} = undef;
    bless $self, $class;
    return $self;
}

sub type {
    return AstType::EXPR;
}

#baseline empty, just here to know we must override
sub mutations {
}

####################################################################
# BINARY OP AST NODE
####################################################################
package AstBinaryOp;
our @ISA = qw(AstExpr);

sub new {
    my $class = shift;
    my $super_fileline = shift;
    my $super_mutation = shift;
    my $self = $class->SUPER::new($super_fileline, $super_mutation);
    $self->{_op} = undef;
    $self->{_lhs} = undef;
    $self->{_rhs} = undef;
    $self->{_nosteal} = 0;
    bless $self, $class;
    return $self;
}

sub isComplete {
    my $self = shift;
    if(defined $self->{_lhs} && defined $self->{_rhs}){
	return 1;
    } else {
	return 0;
    }
}

sub type {
    return AstType::BINARYOP;
}

sub setRHS {
    my $self = shift;
    $self->{_rhs} = shift;
}

sub setLHS{
    my $self = shift;
    $self->{_lhs} = shift; 
}

sub addTerm {
    my $self = shift;
    if(!(defined $self->{_lhs})){
	$self->{_lhs} = shift;
    } elsif(!(defined $self->{_rhs})){
	$self->{_rhs} = shift;
    } 
}

sub stealOperand {
    my $self = shift;
    if((defined $self->{_lhs})){
	my $temp = $self->{_lhs};
	$self->{_lhs} = undef;
	return $temp;
    } elsif(defined $self->{_rhs}){
	my $temp = $self->{_rhs};
	$self->{_rhs} = undef;
	return $temp;
    }
    return undef;
}

sub getOp {
    my $self = shift;
    return $self->{_op};
}

sub setOp(){
    my $self = shift;
    $self->{_op} = shift;
}

sub setNoSteal(){
    my $self = shift;
    $self->{_nosteal} = 1;
}

sub noSteal(){
    my $self = shift;
    return $self->{_nosteal};
}
#TODO
sub print{
    my $self = shift;
    $self->{_lhs}->print();
    if($self->{_op} eq 'dly_assign'){
	print ' <= ';
    } elsif ($self->{_op} eq 'blk_assign'){
	print ' = ';
    } elsif ($self->{_op} eq '[]') {
	print '['
    } else {
	print ' ', $self->{_op}, ' ';
    }
    $self->{_rhs}->print();
    
    if($self->{_op} eq '[]'){
	print ']';
    }
}

####################################################################
# UNARY OP AST NODE
####################################################################
package AstUnaryOp;
our @ISA = qw(AstExpr);

sub new {
    my $class = shift;
    my $super_fileline = shift;
    my $super_mutation = shift;
    my $self = $class->SUPER::new($super_fileline, $super_mutation);
    $self->{_op} = undef;
    $self->{_rhs} = undef;
    $self->{_nosteal} = 0;
    bless $self, $class;
    return $self;
}

sub type {
    return AstType::UNARYOP; 
}

sub isComplete {
    my $self = shift;
    if(defined $self->{_rhs}){
	return 1;
    } else {
	return 0;
    }
}

sub setRHS {
    my $self = shift;
    $self->{_rhs} = shift;
}

sub addTerm {
    my $self = shift;
    if(!(defined $self->{_rhs})){
	$self->{_rhs} = shift;
    }
}

sub stealOperand {
    my $self = shift;
    if((defined $self->{_rhs})){
	my $temp = $self->{_rhs};
	$self->{_rhs} = undef;
	return $temp;
    }
    return undef;
}

sub getOp {
    my $self = shift;
    return $self->{_op};
}

#TODO
sub print(){
    my $self = shift;
    if($self->{_op} == '()'){
	print "(";
	$self->{_rhs}->print();
	print ")";
    } else {
	print $self->{_op};
	$self->{_rhs}->print()
    }
}

sub setOp(){
    my $self = shift;
    $self->{_op} = shift;
}

sub setNoSteal(){
    my $self = shift;
    $self->{_nosteal} = 1;
}

sub setSteal(){
    my $self = shift;
    $self->{_nosteal} = 0;
}

sub noSteal(){
    my $self = shift;
    return $self->{_nosteal};
}

####################################################################
# TRINARY OP AST NODE
####################################################################
package AstTriOp;
our @ISA = qw(AstExpr);

sub new {
    my $class = shift;
    my $super_fileline = shift;
    my $super_mutation = shift;
    my $self = $class->SUPER::new($super_fileline, $super_mutation);
    $self->{_op} = undef;
    $self->{_lhs} = undef;
    $self->{_rhs} = undef;
    $self->{_ths} = undef;
    $self->{_nosteal} = 0;
    bless $self, $class;
    return $self;
}

sub type {
    return AstType::TRINARYOP;
}

sub isComplete {
    my $self = shift;
    if((defined $self->{_lhs}) && (defined $self->{_rhs}) && (defined $self->{_ths})){
	return 1;
    } else {
	return 0;
    }
}

sub setOp(){
    my $self = shift;
    $self->{_op} = shift;
}


sub addTerm {
    my $self = shift;
    if(!(defined $self->{_lhs})){
	$self->{_lhs} = shift;
    } elsif(!(defined $self->{_rhs})){
	$self->{_rhs} = shift;
    } elsif(!(defined $self->{_ths})) {
	$self->{_ths} = shift;
    }
}

sub stealOperand {
    my $self = shift;
    if((defined $self->{_lhs})){
	my $temp = $self->{_lhs};
	$self->{_lhs} = undef;
	return $temp;
    } elsif(defined $self->{_rhs}){
	my $temp = $self->{_rhs};
	$self->{_rhs} = undef;
	return $temp;
    } elsif(defined $self->{_ths}) {
        my $temp = $self->{_ths};
	$self->{_ths} = undef;
	return $temp;
    }
    return undef;
}

sub getOp {
    my $self = shift;
    return $self->{_op};
}

#TODO
sub print {
}

sub setNoSteal(){
    my $self = shift;
    $self->{_nosteal} = 1;
}

sub setSteal(){
    my $self = shift;
    $self->{_nosteal} = 0;
}

sub noSteal(){
    my $self = shift;
    return $self->{_nosteal};
}

####################################################################
# NUMBER AST NODE
####################################################################
package AstNum;
our @ISA = qw(AstExpr);

sub new {
    my $class = shift;
    my $super_fileline = shift;
    my $super_mutation = shift;
    my $self = $class->SUPER::new($super_fileline, $super_mutation);
    $self->{_lvalue} = 0;
    $self->{_type} = '';
    $self->{_width} = 0;
    bless $self, $class;
    return $self;
}

sub setNum {
    my $self = shift;
    $self->{_width} = shift;
    $self->{_lvalue} = shift;
    $self->set_type(shift);
}

sub set_type {
    my $self = shift;
    my $type = shift;
    if (lc($type) eq 'bin' || lc($type) || 'hex' || lc($type) eq 'dec' || lc($type) eq 'oct'){
	$self->{_type} = lc($type);
    }
}

sub type {
    return AstType::NUMBER;
}

#TODO
sub print {
    my $self = shift;
    print $self->{_type}, " ", $self->{_width}, " ", $self->{_lvalue}, "\n";
    if($self->{_type} eq 'bin'){
	if($self->{_width} != 0){
	    printf "%u'b%.*b", $self->{_width}, $self->{_width}, $self->{_lvalue};
	}
    } elsif ($self->{_type} eq 'dec') {
	print $self->{_lvalue};
    } elsif ($self->{_type} eq 'hex') {
	if($self->{_width} != 0){
	    my $print_width = (($self->{_width} % 4) > 0) ? $self->{_width} + 1 : $self->{_width};
	    printf "%u x%.*x", $self->{_width}, $print_width, $self->{_lvalue};
	} else {
	    printf "%u x%x", $self->{_width}, $self->{_lvalue};
	}
    } elsif ($self->{_type} eq 'oct') {
	if($self->{_width} != 0){
	    my $print_width = (($self->{_width} % 3) > 0) ? $self->{_width} + 1 : $self->{_width};
	    printf "%u o%.*o", $self->{_width}, $print_width, $self->{_lvalue};
	} else {
	    printf "%u o%o", $self->{_width}, $self->{_lvalue};
	}
    }
}

####################################################################
# CONST AST NODE
####################################################################
package AstConst;
our @ISA = qw(AstExpr);

sub new {
    my $class = shift;
    my $super_fileline = shift;
    my $super_mutation = shift;
    my $self = $class->SUPER::new($super_fileline, $super_mutation);;
    $self->{_name} = '';
    bless $self, $class;
    return $self;
}

sub type {
    return AstType::CONST;
}

sub setName {
    my $self = shift;
    $self->{_name} = shift;
}
sub print {
    my $self = shift;
    print $self->{_name};
}
####################################################################
# SYMBOL AST NODE
####################################################################
package AstSymbol;
our @ISA = qw(AstExpr);

sub new {
    my $class = shift;
    my $super_fileline = shift;
    my $super_mutation = shift;
    my $self = $class->SUPER::new($super_fileline, $super_mutation);
    $self->{_var} = ''; 
    bless $self, $class;
    return $self;
}

sub type {
    return AstType::SYMBOL;
}

sub setVar {
    my $self = shift;
    $self->{_var} = shift;
}
#TODO
sub print {
    my $self = shift;
    print $self->{_var};
}

####################################################################
# STMT AST NODE
####################################################################
#makes preceeding nodes into a statement versus expression, the ; operator
package AstStmtOp;

our @ISA = qw(AstExpr);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    bless $self, $class;
    return $self;
}

sub type {
    return AstType::STMT;
}

#TODO
sub print {
    my $self = shift;
    print ";";
}

package AstBuilder;
use Switch;
use Carp;
#this is the primary worker. It builds the AST and enforces rules of recognition. 
#All callbacks pass their tokens up to the builder. 
#base rules 
# if statements
# switch statement
# assignment statements
# wire statements
# assign statements
# preprocessor directives
my %operator_priority = ( 
    '()' => 0,
    '!' => 10, 
    '~' => 10, 
    '*' => 10, 
    '/' => 10,
    '%' => 10,
    '+' => 20,
    '-' => 20,
    '<<' => 20,
    '>>' => 20,
    '<' => 30,
    '>' => 30,
    '<=' => 30,
    '>=' => 30,
    '==' => 30,
    '!=' => 30,
    '===' => 30,
    '!==' => 30,
    '&&' => 50,
    '||' => 50,
    '?:' => 60,
 );

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
    DEF => 13,
    #need some operator
    PREPROC_DEFINE_SYM => 14,
    PREPROC_DEFINE_EXPR => 15,
    
};

sub new {
    my $class = shift;
    my $self = {
	_state => START,
        mutation_gen => shift,
	expr_lines => { },
	_num_assign => 0,
	_curr_expr => undef,
    };
    $self->{_stack} = [];
    state $num_instance = 0;
    #printf "INSTANCE NUM: %d", $num_instance; 
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
    $self->{expr_lines} = {};
}

#manages the expression recognition state machine
sub accept_token {
    my $self = shift;
    my $token = shift;
    my $token_type = shift;
    my $token_line = shift;
    my $symbol_found = 0;

    state $assign_expr;
    
    printf "Current State: %d %s %s \n", $self->{_state}, $token, $token_type;
    switch ($self->{_state}) {
	case START {
	    #6 edges: S->if key, S->switch Key, S->Assign Key, S->wire key, S->Seq assign
	    if($token_type eq 'KEYWORD') {
		#if
		if($token eq 'if'){
		    #create ASTNODE
		    $self->{_state} = IF_KEY_FOUND; 
		}
		#switch
		elsif($token eq 'switch') {
		    $self->{_state} = SWITCH_KEY;
		}
		#assign
		elsif($token eq 'assign') {
		    $self->{_state} = ASSIGN_SYMBOL;
		}
		#wire
		elsif($token eq 'wire'){
		    $self->{_state} = WIRE_SYMBOL;
		} 
		else {
		    if($token ne 'begin' && $token ne 'end' && $token ne 'else' && $token ne 'default'){
			$self->{_state} = OTHER;
		    }
		}
	    }
	    elsif ($token_type eq 'PREPROC') {
		if($token eq '`define'){
		    $self->{_state} = PREPROC_DEFINE_SYM;
		}
	    }
	    elsif($token_type eq 'SYMBOL') {
		#seq assign
		$self->{_state} = SEQ_ASSIGN;
		$self->{_curr_expr} = $self->parse_expr($token, $token_type, $token_line);
	    }

	    elsif($token_type eq 'EOF'){
		$self->{_state} = TERM;
	    }
	    else{
		$self->{_state} = START;
	    }
	}

	case IF_KEY_FOUND {
	    #accepts a "(" and then moves to expression parsing
	    if($token eq '(') {
		$self->{_state} = IF_EXPR; 
	    }
	}
        case IF_EXPR {
	    #grabs the ")"
	    if($token eq ')'){
		printf "FOUND IF STATEMENT\n";
		$self->{_state} = START;
	    }
	}

	case PREPROC_DEFINE_SYM {
	    #ignoring for now just go back to start once it finds the symbol
	    if($token_type eq 'SYMBOL'){
		$self->{_state} = START;
	    }
	}
	
	case PREPROC_DEFINE_EXPR { #unused for now
	}

	case SWITCH_KEY {
	    # accepts the "("
	    if($token eq '('){
		$self->{_state} = SWITCH_EXPR;
	    }
	}
	case SWITCH_EXPR {
	    #gets the controlling variable and closing ")"
	    if($token eq ')'){
		printf "FOUND SWITCH STATEMENT\n";
		$self->{_state} = START;
	    }
	}
	case ASSIGN_SYMBOL {
	    #this state grabs the symbol and operator.
	    if($token_type eq 'SYMBOL'){
		$symbol_found = 1;
		$self->{_state} = ASSIGN_SYMBOL;
	    }
	    elsif($token eq '=' && $symbol_found == 1){
		$self->{_state} = ASSIGN_EXPR;
	    }
	}
	case ASSIGN_EXPR {
	    #grabs the assigning expression
	    if($token_type eq 'OPERATOR'){
		if($token eq ';'){
		    $self->{_state} = START;
		    $symbol_found = 0;
		}
	    }
	}
	case WIRE_SYMBOL {
	    #grabs the symbol and assignment operator
	    if($token_type eq 'SYMBOL'){
		$symbol_found = 1;
		$self->{_state} = ASSIGN_SYMBOL;
	    }
	    elsif($token eq '=' && $symbol_found == 1){
		$self->{_state} = ASSIGN_EXPR;
	    }    
	}
	case WIRE_EXPR {
	    #grabs the assigning wire expression
	    if($token_type eq 'OPERATOR'){
		if($token eq ';'){
		    $self->{_state} = START;
		    $symbol_found = 0;
		}
	    }
	}
	case SEQ_ASSIGN {
	    #expects the assignment operator
	     if($token_type eq 'OPERATOR'){
		 if($token eq '<='){
		     $self->{_state} = SEQ_ASSIGN_EXPR;
		     $assign_expr = $self->build_ast_node('dly_assign', $token_line, 'BIOP');
		     $assign_expr->setLHS($self->{_curr_expr});
		     $self->clear_expr();
		 }
		 else {
		     $self->{_curr_expr} = $self->parse_expr($token, $token_type, $token_line);
		 }
	     } else {
		     $self->{_curr_expr} = $self->parse_expr($token, $token_type, $token_line);
	     }
	}
	case SEQ_ASSIGN_EXPR {
	    #gets the assigning expression and the terminating condition
	    if($token_type eq 'OPERATOR'){
		if($token eq ';'){
		     #printf "FOUND SEQ NON-BLOCKING ASSIGN STATEMENT\n";
		     $self->{_state} = START;
		     $self->{_num_assign}++;
		     #clear current expr
		     #$self->{_curr_expr}->print();
		     $assign_expr->setRHS($self->{_curr_expr});
		     $assign_expr->print();
		     print "\n";
		     $self->clear_expr();
		 } else {
		     #add token to current expr
		     $self->{_curr_expr} = $self->parse_expr($token, $token_type, $token_line);
		 }
	    } else {
		#add token to current expr
		$self->{_curr_expr} = $self->parse_expr($token, $token_type, $token_line);
	    }
	}
	case TERM {
	    #eof state.
	}
	case OTHER {
	    #skip until ;
	    if($token_type eq 'OPERATOR'){
		 if($token eq ';'){
		     $self->{_state} = START;
		 } elsif ($token eq ')'){
		     $self->{_state} = START;
		 }
	    } 
	}
	case DEF {
	    #wait until ), skip sensitivity list
	    if($token eq ')'){
		$self->{_state} = START; 
	    }
	}
	else { #TODO: error states 
	}
    }
    #printf "NEW STATE: %d \n", $self->{_state};
}

#used when the control FSM expects an expression
sub parse_expr {
    my $self = shift;
    my $token = shift;
    my $token_type = shift;
    my $fileline = shift;

    my $node;
    #this is to deal with spanning operators such as '(EXPR)' or ?: 
    # NOT CURRENTLY IMPLEMENTED TODO: COMPLETE THIS 
    state $triop_state = 'none';
    state $uniop_state = 'none';
    state $uniop_open_count = 0;
    state $bitri_state = 'none';

    if($token eq ':' && $triop_state neq 'none') {
	$token_type = 'TRIOP';
    }

    my $stack_empty = !(defined @{$self->{_stack}});
    
    if($token_type eq 'NUMBER' || $token_type eq 'SYMBOL' || $token_type eq 'PREPROC'){
	#create number or Symbol AST Node and push onto the stack
	#need to peek to see if top is operator (this will complete an accepting operator for rhs)
	if($token_type eq 'NUMBER'){
	    #print "BUILD NUM";
	    $node = $self->build_ast_node($token, $fileline, 'NUM'); 
	    #$node->print();
	    #print "\n";
	} elsif ($token_type eq 'SYMBOL') {
	    $node = $self->build_ast_node($token, $fileline, 'SYMBOL');
	} else {
	    $node = $self->build_ast_node($token, $fileline, 'CONST');
	}
	
	if( $stack_empty ){
	    push @{$self->{_stack}}, $node;
	} elsif($self->{_stack}[-1]->type() eq AstType::BINARYOP){
	    if ($self->{_stack}[-1]->isComplete() == 0){
		#add to the operator rhs
		$self->{_stack}[-1]->setRHS($node);
	    } else {
		#shouldn't happen
		croak "There's a problem with a Binary op adding operand", $token, " at" , $fileline, "\n"; 
	    }
	} elsif ($self->{_stack}[-1]->type() eq AstType::TRINARYOP){
	     if ($self->{_stack}[-1]->isComplete() == 0){
		#add to the operator rhs
		$self->{_stack}[-1]->addTerm($node);
	     } else {
	     	croak "There's a problem with a Trinary op adding operand", $token, " at" , $fileline, "\n";
	     }
	} elsif ($self->{_stack}[-1]->type() eq AstType::UNARYOP){
	     if ($self->{_stack}[-1]->isComplete() == 0){
		#add to the operator rhs
		$self->{_stack}[-1]->setRHS($node);
	     }
	}
    } elsif ($token_type eq 'OPERATOR'){
	#handle this last, it is the most complicated
	#most importantly, order of operations "steals" rhs of previous nodes unless locked by parenthesis
	
	my $op_type = AstType->getOpType($token);
	#special case hack
	if($token eq ':' && $triop_state neq 'none'){
	    $op_type == 'TRIOP';
	}
	#check the type of operator
	switch($op_type) {
	    case 'BIOP' {
		#build ast node, assign proper operation
		#if there is something on the stack, check type
		#if num/sym/const go ahead and grab
		#else check op priority
		#push onto stack
		$node = $self->build_ast_node($token, $fileline, 'BIOP');
		$node->setOp($token);

		if($stack_empty){
		    push @{$self->{_stack}}, $node;
		} else {
		    my $type = $self->{_stack}[-1]->type();
		    if($type eq AstType::UNARYOP || $type eq AstType::BINARYOP || $type eq AstType::TRINARYOP){
			if($self->has_precedence($node, $self->{_stack}[-1]) && !($self->{_stack}[-1]->noSteal()) ){
			    #steal
			    my $temp = $self->{_stack}[-1]->stealOperand();
			    $node->setRHS($temp);
			    $self->{_stack}[-1]->addTerm($node); #adds to the appropriate term
			    push @{$self->{_stack}}, $node; #pushes onto the stack to gain LHS of the operand
			} else {
			    #the top node of the stack is complete and it becomes the rhs of the operand
			    #additionally, since it's complete, it no longer needs to be on the stack
			    $node->setRHS($self->{_stack}[-1]);
			    pop @{$self->{_stack}};
			    push @{$self->{_stack}} , $node;
			}
		    }
		}
	    } case 'UNIOP' {
		#here is what happens with a () it starts and blocks the top of the stack from being stolen
		if ($uniop_state eq 'none'){
		    if($token eq '('){
			#change state
			$uniop_state = 'wait_paren';
			$uniop_open_count++;
		        if( !$stack_empty ){
			    $self->{_stack}[-1]->setNoSteal();
			}
		    } elsif ($token eq '~' || $token eq '!'){
			#build a node as normal
		        $node = $self->build_ast_node($token, $fileline, 'UNIOP');
			push @{$self->{_stack}}, $node;
		    } else {
			#FAIL
			croak "Bad formation of Uniop $token at $fileline"; 
		    }
		} elsif(($uniop_state eq 'wait_paren')){
		    if($token eq ')'){
			#create the paren node
			$uniop_open_count--;
			$node = $self->build_ast_node('()', $fileline, 'UNIOP');
			$node->setRHS($self->{_stack}[-1]);
			pop @{$self->{_stack}[-1]}
			if(!(defined @{$self->{_stack}} && nested_paren_counter == 0;)){
			    $self->{_stack}[-1]->setSteal():
			}
			push @{$self->{_stack}}, $node;
		    } elsif ($token eq '~' || $token eq '!'){
			  $node = $self->build_ast_node($token, $fileline, 'UNIOP');
		    } elsif($token eq '(')
			$uniop_open_count++;
		        if( !$stack_empty ){
			    $self->{_stack}[-1]->setNoSteal();
			}
		    }
		} 
		
	    } case 'TRIOP' { #multi-part operators
		if($triop_state eq 'none' && $token eq '?'){
		    $triop_state = 'wait_colon';
		} elsif ($triop_state eq 'wait_colon' && $token eq ':') {
		    $triop_state = 'none';
		    $node = $self->build_ast_node('?:', $fileline, 'TRIOP');
		    $node->setRHS($self->{_stack}[-1]);
		    pop @{$self->{_stack}};
		    $node->setLHS($self->{_stack}[-1]);
		    pop @{$self->{_stack}};
		    $triop_state = 'none';
		} else {
		    croak 'Invalid triop token';
		}
	  
	    } case 'BI-UNI' {
		#contextual information determines if the operator is a biop or uniop
		#e.g. negative signs
		if($stack_empty) {
		    #must be biop
		    $node = $self->build_ast_node($token, $fileline, 'UNIOP');
		    push @{$self->{_stack}}, $node;
		} elsif($self->{_stack}[-1]->type() eq AstType::BINARYOP ||
		   $self->{_stack}[-1]->type() eq AstType::TRINARYOP || 
		   $self->{_stack}[-1]->type() eq AstType::UNARYOP)
		{
		    #contextual
		} else {
		    #is a biop
		}
		
	    } case 'BI-TRI' {
		#select operators
		#based on the number of arguments taken
		if($token eq  '['){
		    $bitri_state = 'bitri_found';
		} elsif($bitri_state eq 'bitri_found' && $token eq ':') {
		    $bitri_state = 'triop_found';
		} elsif($bitri_state eq 'bitri_found' && $token eq ']'){
		    #create biop
		    $node = $self->build_ast_node('[]', $fileline, 'BIOP');
		    $node->setRHS($self->{_stack}[-1]);
		    pop @{$self->{_stack}};
		    $node->setLHS($self->{_stack}[-1]);
		    pop @{$self->{_stack}};
		    push @{$self->{_stack}}, $node;
		} elsif ($bitri_state eq 'triop_found' && $token eq ']'){
		    #create triop
		    $node = $self->build_ast_node('[:]', $fileline, 'TRIOP');
		    $node->setTHS($self->{_stack}[-1]);
		    pop @{$self->{_stack}};
		    $node->setRHS($self->{_stack}[-1]);
		    pop @{$self->{_stack}};
		    $node->setLHS($self->{_stack}[-1]);
		    pop @{$self->{_stack}};
		    push @{$self->{_stack}}, $node;
		} else {
		    croak 'Invalid biop or triop construction\n';
		}
	    }
	}
    } 

    if(0+@{$self->{_stack}} != 0){
	return $self->{_stack}[0];
    } else {
	return undef;
    }
}

sub has_precedence {
    my $self = shift;
    my $op1 = shift;
    my $op2 = shift;
    
    print "CHECK PRECENDENCE\n"; 
    if($AstBuilder::operator_priority->{$op1->getOp()} < $AstBuilder::operator_priority->{$op2->getOp()}){
	return 1;
    } else {
	return 0;
    }
}

sub clear_expr {
    my $self = shift;
    $self->{_curr_expr} = undef;
    $self->{_stack} = ();
}

sub get_expr {
    my $self = shift;
    return $self->{_curr_expr};
}

#builds a simple Ast Node
sub build_ast_node{
    my $self = shift;
    my $token = shift;
    my $lineno = shift;
    my $node_type = shift;

    my $node = undef;

    if($node_type eq 'BIOP') {
	$node = AstBinaryOp->new();
	$node->setOp($token);
    } 
    elsif ($node_type eq 'UNIOP') {
	#located before its operand always
	$node = AstUnaryOp->new($lineno, 0);
	$node->setOp($token);
    }
    elsif ($node_type eq 'TRIOP') {
	#sometimes in multiple parts, requires multiple tokens, don't handle until later
	$node = AstTrinaryOp->new($lineno, 0);
	$node->setOp($token);
    }
    elsif ($node_type eq 'SYMBOL') {
	#trivial case, just create symbol node, we don't mutate these
	$node = AstSymbol->new($lineno, 0);
	$node->setVar($token);
    }
    elsif ($node_type eq 'NUM') {
	#also trivial, just parse into a number
	$node = AstNum->new($lineno, 0);
	my @num_info = $self->parse_num($token);
	$node->setNum($num_info[0], $num_info[1], $num_info[2]); #width, value, type
    }
    elsif ($node_type eq 'CONST') {
	#frequently trivial, usually a preprocessor directive
	$node = AstConst->new($lineno, 0);
	$node->setName($token);
    }
    
    return $node;
}

#parses a number returns the type of number and the value as an integer or float
#handles binary, oct, hex and dec
sub parse_num {
    my $self = shift;
    my $toparse = shift;
    
    my @ret = (0, 0, 'NONE');

    #regex to match and assign to parse
    if($toparse =~ /'[bdho]/){
	my $width;
	my $type;
	my $value;
	($width, $type, $value) = ($toparse =~ /(\d*)('[bdho])([A-F0-9]+)/i);
	if(length($width) != 0){
	    $ret[0] = oct($width);
	} 
	if ($type eq '\'b') {
	    $ret[1] = oct('0b'.$value);
	    $ret[2] = 'BIN';
	} elsif ($type eq '\'h') {
	    $value = '0x'.$value;
	    $ret[1] = oct($value);
	    $ret[2] = 'HEX';
	} elsif ($type eq '\'o') {
	    $value = '0o'.$value;
	    $ret[1] = oct($value);
	    $ret[2] = 'OCT';
	}
    } else {
	$ret[0] = -1;
	if($toparse =~ /\d+/i){
	    $ret[0] = -1;
	    $ret[1] = oct($toparse); #should be base-10, oct is an easy "cast" for readability
	    $ret[2] = 'DEC'
	} else {
	    #fail!
	    croak "INVALID NUMBER WITHOUT TYPE IDENTIFIER";
	}
    }
    return @ret;
}
