%% -*- mode: nitrogen -*-
-module (settings).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").
-include("records.hrl").


main() -> 
    case wf:role(managers) of
        true ->
            #template { file="./site/templates/1_columns.html" };
        false ->
            wf:redirect_to_login("/login")
    end.

title() -> "Hello from administration.erl!".


list_left () -> 
    [
        #listitem{ body=#link{ text="Home", url="index" }},		
        #listitem{ class="active",body=#link{ text="Settings", url="settings" }},
        #listitem{ body=#link{ text="Updates", url="updates" }},
        #listitem{ body=#link{ text="Scenarios", url="scenarios" }}
    ].

right_body() -> 
    [
        #panel { style="margin: 50px 100px;", body=[
            #span { text="Hello from administration.erl!" },

            #p{},
            #button { text="Click me!", postback=click },

            #p{},
            #panel { id=placeholder }
        ]}
    ].

logout_site() -> 
    [
         #button { class="btn btn-danger ", id=button, text="Logout", postback=logout}
    ].
	
event(logout) ->
    wf:logout(),
    wf:redirect_from_login("/login");

	
event(click) ->
    wf:insert_top(placeholder, "<p>You clicked the button!").
