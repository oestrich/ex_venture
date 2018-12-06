Definitions.

TagOpen = {
ClosingTagOpen = {/
TagClose = }
ClosingSlash = /
VariableOpen = \[
VariableClose = \]
Word = [^{}\n\[\]=\s'"]+
Space = \s+
Quote = ['"]
NewLine = (\n|\n\r|\r)
Equal = =

Rules.

{Word} : {token, {word, TokenChars}}.
{Quote} : {token, {quote, TokenChars}}.
{Space} : {token, {space, TokenChars}}.
{NewLine} : {token, {new_line, TokenChars}}.
{TagOpen} : {token, {'{', TokenChars}}.
{ClosingTagOpen} : {token, {'{/', TokenChars}}.
{TagClose} : {token, {'}', TokenChars}}.
{Equal} : {token, {'=', TokenChars}}.
{VariableOpen} : {token, {'[', TokenChars}}.
{VariableClose} : {token, {']', TokenChars}}.

Erlang code.
