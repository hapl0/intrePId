%% -*- mode: nitrogen -*-
-module (scenarios).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").
-include("records.hrl").

main() -> 
    case wf:role(managers) of
        true ->
            #template { file="./site/templates/scenarios.html" };
        false ->
            wf:redirect_to_login("/login")
    end.

title() -> "Hello from scenario.erl!".



list_left () -> 
	
	 
    [
        #listitem{ body=#link{ text="Home", url="index" }},		
        #listitem{ body=#link{ text="Settings", url="settings" }},
        #listitem{ body=#link{ text="Updates", url="updates" }},
        #listitem{ class="active",body=#link{ text="Scenarios", url="scenarios" }}
    ].

title_body() -> 
    [
        #image {class="pull-left", image="images/DefaultIcon/png/32x32/search.png"},
        #h3 {text="Scenario"}
    ].

bottom_body() -> 
    [
        #button {class="btn btn-success", text="Validate", id=submit, postback=validate}
    ].

    % Binding data stored in a simple list.
get_data() -> [
    ["10.0.0.1", "24", {data,1}],
    ["10.0.0.2", "24", {data,2}],
    ["10.0.0.3", "24", {data,3}]    
  ].

get_map() -> 
    %% Binding map is positional...
    [
        titleLabel@text, 
        mask@text,
        remove_ip@postback
    ].
left_body() -> 
    Data_include = [],
    Map = get_map(),
    Body = [

        
        #p{},

        #label {class="label label-success",text="include IP"},
        #br {},
        #textbox { id=include_ip, next=submit},
        #br {},
        #button {class="btn btn-success ",text="add", id=submit_include_ip, postback=add_include_ip},
        
        #br {},
        #br {},
        #table { id=tableBinding_include, class="table table-striped", rows=[

        
            #bind { data=Data_include, map=Map, body=#tablerow {cells=[
            #tablecell { id=titleLabel },
            #tablecell { body=#button { class="btn btn-danger ",id=remove_ip, text="remove", postback=remove_include_ip} }
               
            ]}}
        ]}
    ],
        
    wf:wire(submit_include_ip, include_ip, #validate { validators=[
        #custom { text="", tag=ip_ok, function=fun ip_validator/2 }
    ]}),

    Body.


right_body() -> 
    Data_exclude = get_data(),
    Map = get_map(),
    [
        #p{},

        #label {class="label label-important",text="exclude IP"},
        #br {},
        #textbox { id=exclude_ip, next=submit },
        
        #br {},
        #button {class="btn btn-success ",text="add", id=submit, postback=add_exclude_ip},
        
        #br {},
        #br {},
        #table { id=tableBinding_exclude, class="table table-striped", rows=[
        
            #bind {  data=Data_exclude, map=Map, body=#tablerow {cells=[
            #tablecell { id=titleLabel },
            #tablecell { body=#button { class="btn btn-danger ",id=remove_ip, text="remove", postback=remove_exclude_ip } }
            
            ]}}
        ]}
    ].


	
logout_site() -> 
    [
         #button { class="btn btn-danger ", id=button, text="Logout", postback=logout}
    ].

event(add_include_ip) ->
    Value=wf:q(include_ip),
    [Ip|Mask] = string:tokens(string:to_lower(Value),"/"),
    Data = [
    [Ip, Mask, {data,1}] 
    ],
    wf:wire(bottom_body, #show { effect=slide, speed=500 }),
    Map = get_map(),
   
    wf:update(tableBinding_include, #table { rows= [

            #bind { data=Data, map=Map, body=#tablerow {cells=[
            #tablecell { id=titleLabel },
            #tablecell { id=mask},
            #tablecell { body=#button { class="btn btn-danger ",id=remove_ip, text="remove", postback=remove_exclude_ip } }
             
            ]}}
        ]}
    );


event(add_exclude_ip) ->
    wf:logout(),
    wf:redirect_from_login("/login");

event(remove_include_ip) ->
    wf:logout(),
    wf:redirect_from_login("/login");

event(remove_exclude_ip) ->
    %wf:wire(bottom_body, #hide { effect=slide, speed=500 }),
    wf:logout(),
    wf:redirect_from_login("/login");
	
event(logout) ->
    wf:logout(),
    wf:redirect_from_login("/login");

event(validate) ->
    wf:wire(wf:q(validate), #hide { effect=slide, speed=500 });

event(click) ->
    wf:insert_top(placeholder, "<p>You clicked the button!").


ip_validator(_Tag, Value) ->
    Value1 = string:to_lower(Value),   
    Value2 = string:tokens(Value1,"/"),
    [Ip|Mask] = Value2,
    Matches = re:run(Ip, "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"),
    Matches2 = re:run(Mask, "^(|[1-32])"),
    case Matches of 
        nomatch -> false;
        _ -> case Matches2 of
                nomatch -> false;
                _ -> true
            end
    end.