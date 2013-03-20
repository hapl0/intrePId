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

    % Binding data stored in a simple list.
get_data() -> [
    ["10.0.0.1", {data,1}],
    ["10.0.0.2", {data,2}],
    ["10.0.0.3", {data,3}]    
  ].



get_map() -> 
    %% Binding map is positional...
    [
        titleLabel@text, 
        remove_ip@postback
    ].
left_body() -> 
    Data_include = [],
    Map = get_map(),
    Body = [

        #label {class="label label-success",text="include IP"},
        #br {},
        #textbox { id=include_ip, next=submit},
        #br {},
        #button {class="btn btn-success ",text="add", id=submit_include_ip, postback=add_include_ip},
        
        #br {},
        #br {},
        #table { id=tableBinding_include, class="table table-striped", rows=[

        
            #bind {data=Data_include, map=Map, body=#tablerow {cells=[
            #tablecell { id=titleLabel },
            #tablecell { body=#button { class="btn btn-danger ",id=remove_ip, text="remove" } }
            
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
            #tablecell { body=#button { class="btn btn-danger ",id=remove_ip, text="remove" } }
            
            ]}}
        ]}
    ].


	
logout_site() -> 
    [
         #button { class="btn btn-danger ", id=button, text="Logout", postback=logout}
    ].

event(add_include_ip) ->

    Counter = wf:state_default(counter, 1),
    Data = wf:state_default(data_include, []),
    wf:state(data_include,Data:append([wf:q(include_ip), {data,Counter}])),
    Map = get_map(),
   
    wf:update(tableBinding_include, #table {rows= [

            #bind { data=Data, map=Map, body=#tablerow {cells=[
            #tablecell { id=titleLabel },
            #tablecell { body=#button { class="btn btn-danger ",id=remove_ip, text="remove" } }
             
            ]}}
        ]}
    ),   
    wf:state(counter, Counter + 1);


event(add_exclude_ip) ->
    wf:logout(),
    wf:redirect_from_login("/login");

event(remove_include_ip) ->
    wf:logout(),
    wf:redirect_from_login("/login");

event(remove_exclude_ip) ->
    wf:logout(),
    wf:redirect_from_login("/login");
	

event({data, Data}) ->
    Message = "Clicked On Data: " ++ wf:to_list(Data),
    wf:wire(#alert { text=Message }),
    ok;

event(logout) ->
    wf:logout(),
    wf:redirect_from_login("/login");

event(click) ->
    wf:insert_top(placeholder, "<p>You clicked the button!").


ip_validator(_Tag, Value) ->   
    Value1 = string:to_lower(Value),
    Matches = re:run(Value1, "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"),
    case Matches of 
        nomatch -> false;
        _ -> true
    end. 
    