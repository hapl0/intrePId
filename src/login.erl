%% -*- mode: nitrogen -*-
-module (login).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").
-include("records.hrl").

main() -> #template { file="./site/templates/login.html" }.

title() -> "Login".

body() -> 
    #panel { style="margin: 50px;", body=[
	#p{},
	#span { text="Password" },
        #br {},
        #password { id=password, next=submit },
        #br {},
	#p{}, 
        #button { class="btn btn-success",text="Login", id=submit, postback=login},
	#br {},
	#flash {}
    ]}.

event(login) ->
    case wf:q(password) == "azerty" of
        true ->
            wf:role(managers, true),
            wf:redirect_from_login("/");
        false ->
            wf:flash("Invalid password.")
    end.
	

