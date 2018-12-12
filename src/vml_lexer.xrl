Definitions.

TagOpen = {
EscapedTagOpen = \\{
ClosingTagOpen = {/
TagClose = }
EscapedTagClose = \\}
OpeningSlash = \\
ClosingSlash = /
VariableOpen = \[
VariableClose = \]
EscapedVariableOpen = \\\[
EscapedVariableClose = \\\]
Word = [^{}\n\[\]=\s'":\\]+
Colon = :
Space = \s+
Quote = ['"]
NewLine = (\n|\n\r|\r)
Equal = =

Rules.

{Word} : {token, {word, TokenLine, TokenChars}}.
{Quote} : {token, {quote, TokenLine, TokenChars}}.
{Space} : {token, {space, TokenLine, TokenChars}}.
{Colon} : {token, {colon, TokenLine, TokenChars}}.
{Equal} : {token, {'=', TokenLine, TokenChars}}.
{NewLine} : {token, {new_line, TokenLine, TokenChars}}.
{TagOpen} : {token, {'{', TokenLine, TokenChars}}.
{EscapedTagOpen} : {token, {'\\{', TokenLine, TokenChars}}.
{ClosingTagOpen} : {token, {'{/', TokenLine, TokenChars}}.
{OpeningSlash} : {token, {'\\', TokenLine, TokenChars}}.
{TagClose} : {token, {'}', TokenLine, TokenChars}}.
{EscapedTagClose} : {token, {'\\}', TokenLine, TokenChars}}.
{VariableOpen} : {token, {'[', TokenLine, TokenChars}}.
{VariableClose} : {token, {']', TokenLine, TokenChars}}.
{EscapedVariableOpen} : {token, {'\\[', TokenLine, TokenChars}}.
{EscapedVariableClose} : {token, {'\\]', TokenLine, TokenChars}}.

Erlang code.
