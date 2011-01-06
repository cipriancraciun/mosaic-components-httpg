%%   The contents of this file are subject to the Mozilla Public License
%%   Version 1.1 (the "License"); you may not use this file except in
%%   compliance with the License. You may obtain a copy of the License at
%%   http://www.mozilla.org/MPL/
%%
%%   Software distributed under the License is distributed on an "AS IS"
%%   basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
%%   License for the specific language governing rights and limitations
%%   under the License.
%%
%%   The Original Code is RabbitMQ.
%%
%%   The Initial Developers of the Original Code are Rabbit Technologies Ltd.
%%
%%   Copyright (C) 2010 Rabbit Technologies Ltd.
%%
%%   All Rights Reserved.
%%
%%   Contributor(s): ______________________________________.
%%
-module(rabbit_upgrade_functions).

-include("rabbit.hrl").

-compile([export_all]).

-rabbit_upgrade({remove_user_scope,  []}).
-rabbit_upgrade({hash_passwords,     []}).
-rabbit_upgrade({add_ip_to_listener, []}).

%% -------------------------------------------------------------------

-ifdef(use_specs).

-spec(remove_user_scope/0  :: () -> 'ok').
-spec(hash_passwords/0     :: () -> 'ok').
-spec(add_ip_to_listener/0 :: () -> 'ok').

-endif.

%%--------------------------------------------------------------------

%% It's a bad idea to use records or record_info here, even for the
%% destination form. Because in the future, the destination form of
%% your current transform may not match the record any more, and it
%% would be messy to have to go back and fix old transforms at that
%% point.

remove_user_scope() ->
    mnesia(
      rabbit_user_permission,
      fun ({user_permission, UV, {permission, _Scope, Conf, Write, Read}}) ->
              {user_permission, UV, {permission, Conf, Write, Read}}
      end,
      [user_vhost, permission]).

hash_passwords() ->
    mnesia(
      rabbit_user,
      fun ({user, Username, Password, IsAdmin}) ->
              Hash = rabbit_access_control:hash_password(Password),
              {user, Username, Hash, IsAdmin}
      end,
      [username, password_hash, is_admin]).

add_ip_to_listener() ->
    mnesia(
      rabbit_listener,
      fun ({listener, Node, Protocol, Host, Port}) ->
              {listener, Node, Protocol, Host, {0,0,0,0}, Port}
      end,
      [node, protocol, host, ip_address, port]).

%%--------------------------------------------------------------------

mnesia(TableName, Fun, FieldList) ->
    {atomic, ok} = mnesia:transform_table(TableName, Fun, FieldList),
    ok.
