%% -------------------------------------------------------------------
%%
%% basho_bench: Benchmarking Suite
%%
%% Copyright (c) 2009-2010 Basho Techonologies
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------
-module(basho_bench_valgen).

-export([new/2,
         dimension/2]).

-include("basho_bench.hrl").

%% ====================================================================
%% API
%% ====================================================================

new({fixed_bin, Size}, _Id) ->
    Source = init_source(),
    fun() -> data_block(Source, Size) end;
new({exponential_bin, MinSize, Lambda}, _Id) ->
    Source = init_source(),
    fun() -> data_block(Source, MinSize + trunc(stats_rv:exponential(1 / Lambda))) end;
new(Other, _Id) ->
    ?FAIL_MSG("Unsupported value generator requested: ~p\n", [Other]).

dimension({fixed_bin, Size}, KeyDimension) ->
    Size * KeyDimension;
dimension(Other, _) ->
    0.0.



%% ====================================================================
%% Internal Functions
%% ====================================================================

init_source() ->
    SourceSz = basho_bench_config:get(value_generator_source_size, 1048576),
    {SourceSz, crypto:rand_bytes(SourceSz)}.

data_block({SourceSz, Source}, BlockSize) ->
    case SourceSz - BlockSize > 0 of
        true ->
            Offset = random:uniform(SourceSz - BlockSize),
            <<_:Offset/bytes, Slice:BlockSize/bytes, _Rest/binary>> = Source,
            Slice;
        false ->
            ?WARN("value_generator_source_size is too small; it needs a value > ~p.\n",
                  [BlockSize]),
            Source
    end.
