%% -*- mode: nitrogen -*-
-module (index).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").





main() -> 
    case wf:role(managers) of
        true ->
            #template { file="./site/templates/1_columns.html" };
        false ->
            wf:redirect_to_login("/login")
    end.


title() -> "intrePId".


stats_mem() ->
    wf:comet(fun() -> update_mem() end),
    [
        #h4 {id=mem, text="-"}
    ].

update_mem() ->
    timer:sleep(1000),
    MemoryData=memsup:get_memory_data(),
    MemoryUse=(element(2,MemoryData)/element(1,MemoryData))*100,
    MemoryUsePercent=lists:concat([erlang:round(MemoryUse)]),
    FormatMemoryUse=string:concat(MemoryUsePercent,"% "),
    wf:update(mem, FormatMemoryUse),
    wf:flush(),
    update_mem().


stats_cpu() ->
    wf:comet(fun() -> update_cpu() end),
    [
        #h4 {id=cpu, text="-"}
    ].
	

update_cpu() ->
    timer:sleep(1000),
    CPULoad=lists:concat([erlang:round(cpu_sup:util())]),
    FormatCPULoad=string:concat(CPULoad,"% "),
    wf:update(cpu, FormatCPULoad),
    wf:flush(),
    update_cpu().

stats_hdd() ->
    wf:comet(fun() -> update_hdd() end),
    [
        #h4 {id=hdd, text="-"}
    ].


update_hdd() ->
    timer:sleep(1000),
    DiskPart=disksup:get_disk_data(),
    DiskRoot=lists:keysearch("/", 1, DiskPart),
    DiskRootUse=lists:concat([erlang:round(element(3,element(2,DiskRoot)))]),
    FormatDiskRootUse=string:concat(DiskRootUse,"% "),
    wf:update(hdd, FormatDiskRootUse),
    wf:flush(),
    update_hdd().

list_left () -> 
    [
        #listitem{ class="active",body=#link{ text="Home", url="index" }},		
        #listitem{ body=#link{ text="Settings", url="settings" }},
        #listitem{ body=#link{ text="Updates", url="updates" }},
        #listitem{ body=#link{ text="Scenarios", url="scenarios" }}
    ].



right_body() -> 
    [
        #p{},

        #image{class="pull-left", image="images/DefaultIcon/png/32x32/wi-fi.png"},
        #h3{text="Network"},

        "<div class=\"well\">",
	#literal { text=re:replace(os:cmd("ifconfig wlan0"), "\n", "<br/>", [global, {return, list}]), html_encode=false},
        "</div>",

        #image{class="pull-left", image="images/DefaultIcon/png/32x32/statistics-chart.png"},
        #h3{text="System"},

        "<div class=\"well\">",
        #literal { text=re:replace(os:cmd("w"), "\n", "<br/>", [global, {return, list}]), html_encode=false},
        "</div>"
    ].

logout_site() -> 
    [
         #button { class="btn btn-danger ", id=button, text="Logout", postback=logout}
    ].
	
event(logout) ->
    wf:logout(),
    wf:redirect_from_login("/login").




