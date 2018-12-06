Definitions.

TagOpen = {
ClosingTagOpen = {/
TagClose = }
ClosingSlash = /
VariableOpen = \[
VariableClose = \]
Word = [^{}\n\[\]=\s'":]+
Colon = :
Space = \s+
Quote = ['"]
NewLine = (\n|\n\r|\r)
Equal = =
ResourceOpen = {{
ResourceClose = }}

Rules.

{Word} : {token, {word, TokenLine, TokenChars}}.
{Quote} : {token, {quote, TokenLine, TokenChars}}.
{Space} : {token, {space, TokenLine, TokenChars}}.
{Colon} : {token, {colon, TokenLine, TokenChars}}.
{Equal} : {token, {'=', TokenLine, TokenChars}}.
{NewLine} : {token, {new_line, TokenLine, TokenChars}}.
{TagOpen} : {token, {'{', TokenLine, TokenChars}}.
{ClosingTagOpen} : {token, {'{/', TokenLine, TokenChars}}.
{TagClose} : {token, {'}', TokenLine, TokenChars}}.
{ResourceOpen} : {token, {'{{', TokenLine, TokenChars}}.
{ResourceClose} : {token, {'}}', TokenLine, TokenChars}}.
{TagClose} : {token, {'}', TokenLine, TokenChars}}.
{VariableOpen} : {token, {'[', TokenLine, TokenChars}}.
{VariableClose} : {token, {']', TokenLine, TokenChars}}.

Erlang code.
