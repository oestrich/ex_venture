Nonterminals
markup
tag
attributes
attribute
.

Terminals
word
space
quote
'{'
'{/'
'}'
'='
.

Rootsymbol markup.

markup -> markup markup : ['$1' | '$2'].
markup -> tag : '$1'.
markup -> word : element(2, '$1').
markup -> space : element(2, '$1').
markup -> quote : '$1'.

tag -> '{' word '}' markup '{/' word '}' : {tag, [{name, element(2, '$2')}], '$4'}.
tag -> '{' word space attributes '}' markup '{/' word '}' : {tag, [{name, element(2, '$2')}, {attributes, '$4'}], '$6'}.

attributes -> attribute space attribute : ['$1' | ['$3']].
attributes -> attribute : '$1'.

attribute -> word '=' quote word quote : [{name, element(2, '$1')}, {value, element(2, '$4')}].

Erlang code.
