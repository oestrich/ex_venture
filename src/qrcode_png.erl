%% Copyright 2011 Steve Davis <steve@simulacity.com>
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
% http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

-module(qrcode_png).

%% Shows how to achieve HOTP/SHA1 with a mobile phone using Google Authenticator.
%%
%% This module is a rag-bag of supporting functions, many of which are simplified 
%% extracts from the core libs (?_common, ?_crypto, ?_math, ?_image). This is to 
%% allow a full-cycle demo without requiring open-sourcing of the entire platform.
%% 
%% @ref QR Code: ISO/IEC 18004 (2000, 1st Edition)

%% Google Authenticator Phone App 
%% iPhone:  <http://itunes.apple.com/us/app/google-authenticator/id388497605?mt=8>
%% Android: <https://market.android.com/details?id=com.google.android.apps.authenticator>

%% Google Authenticator URL Specification 
% @ref <http://code.google.com/p/google-authenticator/wiki/KeyUriFormat>
%  otpauth://TYPE/LABEL?PARAMETERS
%  TYPE: hotp | totp
%  LABEL: string() (usually email address)
%  PARAMETERS:
%    digits = 6 | 8 (default 6)
%    counter = integer() (hotp only, default 0?)
%    period = integer() (in seconds, totp only, default 30)
%    secret = binary() base32 encoded
%    algorithm = MD5 | SHA1 | SHA256 | SHA512 (default SHA1)


-include("qrcode.hrl").

-export([simple_png_encode/1]).

-define(TTY(Term), io:format(user, "[~p] ~p~n", [?MODULE, Term])).
-define(PERIOD, 30).


%% Very simple PNG encoder for demo purposes
simple_png_encode(#qrcode{dimension = Dim, data = Data}) ->
	MAGIC = <<137, 80, 78, 71, 13, 10, 26, 10>>,
	Size = Dim * 8,
	IHDR = png_chunk(<<"IHDR">>, <<Size:32, Size:32, 8:8, 2:8, 0:24>>), 
	PixelData = get_pixel_data(Dim, Data),
	IDAT = png_chunk(<<"IDAT">>, PixelData),
	IEND = png_chunk(<<"IEND">>, <<>>),
	<<MAGIC/binary, IHDR/binary, IDAT/binary, IEND/binary>>.

png_chunk(Type, Bin) ->
	Length = byte_size(Bin),
	CRC = erlang:crc32(<<Type/binary, Bin/binary>>),
	<<Length:32, Type/binary, Bin/binary, CRC:32>>.

get_pixel_data(Dim, Data) ->
	Pixels = get_pixels(Data, 0, Dim, <<>>),
	zlib:compress(Pixels).

get_pixels(<<>>, Dim, Dim, Acc) ->
	Acc;
get_pixels(Bin, Count, Dim, Acc) ->
	<<RowBits:Dim/bits, Bits/bits>> = Bin,
	Row = get_pixels0(RowBits, <<0>>), % row filter byte
	FullRow = binary:copy(Row, 8),
	get_pixels(Bits, Count + 1, Dim, <<Acc/binary, FullRow/binary>>).
	
get_pixels0(<<1:1, Bits/bits>>, Acc) ->
	Black = binary:copy(<<0>>, 24),
	get_pixels0(Bits, <<Acc/binary, Black/binary>>);
get_pixels0(<<0:1, Bits/bits>>, Acc) ->
	White = binary:copy(<<255>>, 24),
	get_pixels0(Bits, <<Acc/binary, White/binary>>);
get_pixels0(<<>>, Acc) ->
	Acc.
