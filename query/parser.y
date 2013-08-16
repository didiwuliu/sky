%{

package query

import (
    "bufio"
    "bytes"
    "io"
)

%}

%union{
    token int
    str string
    strs []string
    query *Query
    statement Statement
    statements Statements
    selection *Selection
    selection_field *SelectionField
    selection_fields []*SelectionField
}

%token <token> TSELECT, TGROUP, TBY
%token <token> TSEMICOLON, TCOMMA, TLPAREN, TRPAREN
%token <str> TIDENT

%type <selection> selection
%type <statement> statement
%type <statements> statements
%type <selection_field> selection_field
%type <selection_fields> selection_fields
%type <strs> selection_group_by, selection_dimensions

%%

query :
    statements
    {
        l := yylex.(*yylexer)
        l.query.Statements = $1
    }
;

statements :
    /* empty */
    {
        $$ = make(Statements, 0)
    }
|   statement TSEMICOLON
    {
        $$ = make(Statements, 0)
        $$ = append($$, $1)
    }
|   statements TSEMICOLON statement
    {
        $$ = append($1, $3)
    }
;

statement :
    selection  { $$ = Statement($1) }
;

selection :
    TSELECT selection_fields selection_group_by
    {
        l := yylex.(*yylexer)
        $$ = NewSelection(l.query)
        $$.Fields = $2
        $$.Dimensions = $3
    }
;

selection_fields :
    /* empty */
    {
        $$ = make([]*SelectionField, 0)
    }
|   selection_field
    {
        $$ = make([]*SelectionField, 0)
        $$ = append($$, $1)
    }
|   selection_fields TCOMMA selection_field
    {
        $$ = append($1, $3)
    }
;

selection_field :
    TIDENT TLPAREN TRPAREN
    {
        $$ = NewSelectionField("", $1)
    }
|   TIDENT TLPAREN TIDENT TRPAREN
    {
        $$ = NewSelectionField($3, $1)
    }
;

selection_group_by :
    /* empty */
    {
        $$ = make([]string, 0)
    }
|   TGROUP TBY selection_dimensions
    {
        $$ = $3
    }
;

selection_dimensions :
    TIDENT
    {
        $$ = make([]string, 0)
        $$ = append($$, $1)
    }
|   selection_dimensions TCOMMA TIDENT
    {
        $$ = append($1, $3)
    }
;

%%

type Parser struct {
}

func NewParser() *Parser {
    return &Parser{}
}

func (p *Parser) Parse(r io.Reader) *Query {
    l := newLexer(bufio.NewReader(r))
    yyParse(l)
    return l.query
}

func (p *Parser) ParseString(s string) *Query {
    return p.Parse(bytes.NewBufferString(s))
}

