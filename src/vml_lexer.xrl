Definitions.

LeftBrace = {
RightBrace = }
ClosingSlash = /
TagName = [a-zA-Z]+
Variable = \[[a-zA-Z]+\]
Text = [^{}\n\[\]]+
Resource = (item|npc|room|zone):[0-9]+
NewLine = (\n|\n\r|\r)
Attribute = [a-zA-Z]+=["'].+["']

Rules.

{NewLine} : {token, {new_line, TokenLine, TokenChars}}.
{Text} : {token, {text, TokenLine, TokenChars}}.
{Variable} : {token, {variable, TokenLine, TokenChars}}.
{LeftBrace}{LeftBrace}{Resource}{RightBrace}{RightBrace} : {token, {resource, TokenLine, TokenChars}}.
{LeftBrace}{TagName}(\s{Attribute})*{RightBrace} : {token, {start_tag, TokenLine, TokenChars}}.
{LeftBrace}{ClosingSlash}{TagName}{RightBrace} : {token, {close_tag, TokenLine, TokenChars}}.
{LeftBrace} : {token, {left_brace, TokenLine, TokenChars}}.
{RightBrace} : {token, {right_brace, TokenLine, TokenChars}}.

Erlang code.
