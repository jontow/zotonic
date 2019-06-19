%% @author Arjan Scherpenisse <arjan@scherpenisse.net>
%% @hidden

-module(m_rsc_db_tests).

-include_lib("eunit/include/eunit.hrl").
-include_lib("zotonic.hrl").

modify_rsc_test() ->
    C = z_context:new(testsandboxdb),
    AdminC = z_acl:logon(?ACL_ADMIN_USER_ID, C),
    CatId = m_rsc:rid(text, C),

    ?assertThrow({{error, eacces}, _Trace}, m_rsc:insert([{title, "Hello."}], C)),
    ?assertThrow({{error, eacces}, _Trace}, m_rsc:insert([{title, "Hello."}, {category_id, CatId}], C)),

    {ok, Id} = m_rsc:insert([{title, "Hello."}, {category_id, CatId}], AdminC),

    %% Existence check
    ?assertEqual(true, m_rsc:exists(Id, AdminC)),
    ?assertEqual(true, m_rsc:exists(Id, C)),

    %% Check properties
    ?assertEqual(<<"Hello.">>, m_rsc:p(Id, title, AdminC)),
    ?assertEqual(1, m_rsc:p(Id, version, AdminC)),
    ?assertEqual(false, m_rsc:p(Id, is_featured, AdminC)),
    ?assertEqual(true, m_rsc:p(Id, is_authoritative, AdminC)),
    ?assertEqual(true, m_rsc:is_a(Id, text, AdminC)),

    ?assertEqual(false, m_rsc:p(Id, is_published, AdminC)),
    ?assertEqual(undefined, m_rsc:p(Id, publication_start, AdminC)),
    ?assertEqual(undefined, m_rsc:p(Id, title, C)), %% not visible for anonymous yet

    %% Update
    ?assertThrow({error, eacces}, m_rsc:update(Id, [{title, "Bye."}, {is_published, true}], C)),

    {ok, Id} = m_rsc:update(Id, [{title, "Bye."}, {is_published, true}], AdminC),
    ?assertEqual(<<"Bye.">>, m_rsc:p(Id, title, AdminC)),
    ?assertNotEqual(undefined, m_rsc:p(Id, publication_start, AdminC)),

    ?assertEqual(2, m_rsc:p(Id, version, AdminC)),

    %% Delete
    ?assertThrow({error, eacces}, m_rsc:delete(Id, C)),
    ?assertEqual(ok, m_rsc:delete(Id, AdminC)),

    %% verify that it's gone
    ?assertEqual(undefined, m_rsc:p(Id, title, AdminC)),

    %% Existence check
    ?assertEqual(false, m_rsc:exists(Id, AdminC)),
    ?assertEqual(false, m_rsc:exists(Id, C)),

    ok.


page_path_test() ->
    C = z_context:new(testsandboxdb),
    AdminC = z_acl:logon(?ACL_ADMIN_USER_ID, C),

    {ok, Id} = m_rsc:insert([{title, "Hello."}, {category, text}, {page_path, "/foo/bar"}], AdminC),
    ?assertEqual(<<"/foo/bar">>, m_rsc:p(Id, page_path, AdminC)),
    ok = m_rsc:delete(Id, AdminC).

%% @doc Resource name instead of id as argument.
name_rid_test() ->
    C = z_context:new(testsandboxdb),
    AdminC = z_acl:logon(?ACL_ADMIN_USER_ID, C),
    {ok, Id} = m_rsc:insert([{title, <<"What’s in a name?"/utf8>>}, {category_id, text}, {name, rose}], AdminC),

    m_rsc:get_raw(rose, AdminC),
    ok = m_rsc_update:flush(rose, AdminC),
    {ok, Id} = m_rsc:update(rose, [], AdminC),
    {ok, _DuplicateId} = m_rsc:duplicate(rose, [], AdminC),
    ok = m_rsc:delete(rose, AdminC).

%% @doc Check normalization of dates
normalize_date_props_test() ->
    C = z_context:new(testsandboxdb),
    InPropsA = [
        {"dt:dmy:0:date_start", "13/7/-99"},
        {date_is_all_day, true}
    ],
    OutPropsA = m_rsc_update:normalize_props(undefined, InPropsA, C),
    ?assertEqual({{-99, 7, 13}, {0, 0, 0}}, proplists:get_value(date_start, OutPropsA)),

    InPropsB = [
        {"dt:ymd:0:date_start", "-99/7/13"},
        {date_is_all_day, true}
    ],
    OutPropsB = m_rsc_update:normalize_props(undefined, InPropsB, C),
    ?assertEqual({{-99, 7, 13}, {0, 0, 0}}, proplists:get_value(date_start, OutPropsB)),

    InPropsC = [
        {"dt:dmy:0:date_start", "31/12/1999"},
        {date_is_all_day, true}
    ],
    OutPropsC = m_rsc_update:normalize_props(undefined, InPropsC, C),
    ?assertEqual({{1999, 12, 31}, {0, 0, 0}}, proplists:get_value(date_start, OutPropsC)),

    InPropsD = [
        {"dt:ymd:0:date_start", "1999/12/31"},
        {date_is_all_day, true}
    ],
    OutPropsD = m_rsc_update:normalize_props(undefined, InPropsD, C),
    ?assertEqual({{1999, 12, 31}, {0, 0, 0}}, proplists:get_value(date_start, OutPropsD)),

    InPropsE = [
        {"dt:ymd:0:date_start", "1999-12-31"},
        {date_is_all_day, true}
    ],
    OutPropsE = m_rsc_update:normalize_props(undefined, InPropsE, C),
    ?assertEqual({{1999, 12, 31}, {0, 0, 0}}, proplists:get_value(date_start, OutPropsE)),

    ok.


