Nonterminals
text
markup
tag
tag_name
attributes
attribute
attribute_value
variable
resource
.

Terminals
word
space
quote
colon
dash
new_line
'{'
'{/'
'}'
'['
']'
'='
'\\'
'\\['
'\\]'
'\\{'
'\\}'
.

Rootsymbol text.

text -> markup text : ['$1' | '$2'].
text -> markup : ['$1'].

markup -> resource : '$1'.
markup -> tag : '$1'.
markup -> variable : '$1'.

markup -> word : string('$1').
markup -> space : string('$1').
markup -> quote : string('$1').
markup -> colon : string('$1').
markup -> new_line : string('$1').
markup -> dash : string('$1').

markup -> '=' : string('$1').
markup -> '\\' : string('$1').
markup -> '\\[' : string('$1').
markup -> '\\]' : string('$1').
markup -> '\\{' : string('$1').
markup -> '\\}' : string('$1').

tag -> '{' tag_name '}' text '{/' tag_name '}' : tag('$2', '$4', '$6').
tag -> '{' tag_name '}' '{/' tag_name '}' : tag('$2', [], '$5').
tag -> '{' tag_name space attributes '}' text '{/' tag_name '}' : tag('$2', '$4', '$6', '$8').

tag_name -> word tag_name : [string('$1') | '$2'].
tag_name -> colon tag_name : [string('$1') | '$2'].
tag_name -> dash tag_name : [string('$1') | '$2'].
tag_name -> word : [string('$1')].

attributes -> attribute space attributes : ['$1' | '$3'].
attributes -> attribute : ['$1'].

attribute -> word '=' quote attribute_value quote : attribute('$1', '$4').

attribute_value -> word space attribute_value : [val('$1') | [val('$2') | '$3']].
attribute_value -> word : [val('$1')].

resource -> '{' '{' word colon word '}' '}' : {resource, val('$3'), val('$5')}.

variable -> '[' word ']' : {variable, val('$2')}.
variable -> '[' space word ']' : {variable, val('$2'), val('$3')}.
variable -> '[' new_line word ']' : {variable, val('$2'), val('$3')}.

Erlang code.

string(V) -> {string, val(V)}.
val({_, _, V}) -> V.

attribute(Name, Val) -> {val(Name), Val}.
attributes(A) -> {attributes, A}.

tag(StartName, Markup, EndName) ->
  if
  StartName =:= EndName ->
    {tag, [{name, StartName}], Markup};
  true ->
    return_error(1, tag_mismatch_msg(StartName, EndName))
  end.

tag(StartName, Attributes, Markup, EndName) ->
  if
  StartName =:= EndName ->
    {tag, [{name, StartName}, attributes(Attributes)], Markup};
  true ->
    return_error(1, tag_mismatch_msg(StartName, EndName))
  end.

tag_mismatch_msg(StartName, EndName) ->
  lists:concat(['\'', val(StartName), '\' does not match closing tag name \'', val(EndName), '\'']).
