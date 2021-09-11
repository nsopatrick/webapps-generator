{% import 'macros.jinja' as macros -%}
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_error)).
:- use_module(library(http/json_convert)).

% This module contains our homepage.
:- use_module(home_page).

% input.pl is the prolog program for which we are generating a web app.
:- include('./input/input.pl').
{#### URL HANDLERS DEFINITION example: http_handler('/person', handle_person_post, [methods([post])]). #}
% Home page URL handlers.
:- http_handler('/', display_home_page, []).
{% call(term) macros.facts_handlers(data) -%}
% URL handlers for {{term['name'] | lower}}/{{term['arguments'] | length }}
:- http_handler('/{{term['name'] | lower}}', handle_{{term['name'] | lower}}_post, [methods([post])]).
:- http_handler('/{{term['name'] | lower}}/ask', handle_{{term['name'] | lower}}_criteria, [methods([get])]).
:- http_handler('/{{term['name'] | lower}}/del', handle_{{term['name'] | lower}}_delete, [methods([delete])]).
:- http_handler('/{{term['plural'] | lower}}', handle_{{term['plural'] | lower}}_list_all, [methods([get])]).
{% endcall %}

{%- call(term) macros.rules_handlers(data) %}
% URL handler for {{term['name'] | lower}}/{{term['arguments'] | length }}
:- http_handler('/requests/{{term['name'] | lower}}', handle_request_{{term['name'] | lower}}, [methods([get])]).
{% endcall -%}

{#### DYNAMICS PREDICATES DECLARATION example: :- dynamic person/2 #}
{%- call(term) macros.facts_handlers(data) -%}
:- dynamic {{term['name'] | lower}}/{{term['arguments'] | length }}. 
{%- endcall %}
{#### ADD method for each dynamic predicate example: add_person(Name, Age) :- assertz(person(Name, Age)). #}
{%- call(term) macros.facts_handlers(data) -%}
add_{{term['name'] | lower}}({% for key in term['arguments'] %}{{key | capitalize }}{% if not loop.last %}, {% endif %}{% endfor %}) :- assertz({{term['name']}}({% for key in term['arguments'] %}{{key | capitalize }}{%if not loop.last %},{% endif %}{% endfor %})).
{%- endcall %}
{#### Handle POST methods #############################################
example: handle_person_post(Request) :-                               #
#          member(method(post), Request), !,                          #
#          http_read_json_dict(Request, _{name: Name, age: Age}),     #
#          atom_string(NName, Name),                                  #
#          atom_string(AAge, Age),                                    #
#          atom_number(AAge, AAAge),                                  #
#          add_person(NName, AAAge) ->                                #
#          prolog_to_json(success, JSONOut),                          #
#          reply_json(JSONOut);                                       #
#          prolog_to_json(failure, JSONOut),                          #
#          reply_json(JSONOut).                                       #
#######################################################################}
% POST methods
% curl --header 'Content-Type:application/json' --request POST --data '{"name":"JJ","age":12}' 'http://localhost:8000/person' 
{% call(term) macros.facts_handlers(data) -%}
handle_{{term['name'] | lower}}_post(Request) :- 
     member(method(post), Request), !, 
     http_read_json_dict(Request, _{{'{'}}{% for key in term['arguments'] %}{{key | lower }}:{{key | capitalize }}{% if not loop.last %}, {% endif %}{% endfor %}{{'}'}}),
     {%- for key in term['arguments'] %}
       {%- if term['arguments'][key]['type'] == 'string' %}
     atom_string(S{{key | capitalize}}, {{key | capitalize}}),
       {%- elif term['arguments'][key]['type']  == 'number' %}
     atom_string(N{{key | capitalize}}, {{key | capitalize}}),  
     atom_number(N{{key | capitalize}}, NN{{key | capitalize}}),
       {%- else %}
     UNKNOWN DATA TYPE FOR ARGUMENT {{term['name']}},.
       {% endif %}
     {%- endfor %}
     add_{{term['name'] | lower}}({%- for key in term['arguments'] %}{%- if term['arguments'][key]['type'] == 'string'-%}   S{{key | capitalize}}{%- elif term['arguments'][key]['type']  == 'number' %}NN{{key | capitalize}}{%- else -%}{%- endif -%}{%- if not loop.last -%}, {%- endif -%}{%- endfor -%}) ->
     prolog_to_json(success, JSONOut), 
     reply_json(JSONOut,[status(201)]);
     prolog_to_json(failure, JSONOut),
     reply_json(JSONOut, [status(409)]).   
{% endcall %}

{# LIST_ALL method for each dynamic predicate 
example: list_people(_{name:Name, age:Age},L):- findall(_{name:Name,age:Age}, person(Name, Age), L). #}
{%- call(term) macros.facts_handlers(data) -%}
list_{{term['plural']}}(L) :- findall(_{{'{'}}{% for key in term['arguments'] %}{{key | lower }}:{{key | capitalize }}{% if not loop.last %}, {% endif %}{% endfor %}{{'}'}}, {{term['name']}}({% for key in term['arguments'] %}{{key | capitalize }}{%if not loop.last %},{% endif %}{% endfor %}), L).
{% endcall %}

% Handle GET ALL requests (no parameter)
{%- call(term) macros.facts_handlers(data) -%}
handle_{{term['plural'] | lower}}_list_all(_Request) :-
    list_{{term['plural']}}(L) ->
    reply_json_dict(_{result:L}, [status(200)]);
    prolog_to_json(failure, JSONOut),
    reply_json(JSONOut, [status(409)]).
{% endcall %}

{#### Search by criteria method for each dynamic predicate 
example: list_person(_{name:Name, age:Age},L):- findall(_{name:Name,age:Age}, person(Name, Age), L). #}
{%- call(term) macros.facts_handlers(data) %}
list_{{term['name']}}(_{{'{'}}{% for key in term['arguments'] %}{{key | lower }}:{{key | capitalize }}{% if not loop.last %}, {% endif %}{% endfor %}{{'}'}},L):- findall(_{{'{'}}{% for key in term['arguments'] %}{{key | lower }}:{{key | capitalize }}{% if not loop.last %}, {% endif %}{% endfor %}{{'}'}}, {{term['name']}}({% for key in term['arguments'] %}{{key | capitalize }}{%if not loop.last %},{% endif %}{% endfor %}), L).
{%- endcall %}


% Handle GET requests with parameters in URL 
{%- call(term) macros.facts_handlers(data) %}
handle_{{term['name']}}_criteria(Request) :-
    http_parameters(Request,
    [
        {%- for key in term['arguments'] %}
          {%- if term['arguments'][key]['type'] == 'string' %}
     {{key | lower}}({{key | capitalize}}, [optional(true)]){% if not loop.last %}, {% endif %}
          {%- elif term['arguments'][key]['type']  == 'number' %}
     {{key | lower}}({{key | capitalize}}, [number, optional(true)]){% if not loop.last %}, {% endif %}
          {%- else %}
     UNKNOWN DATA TYPE FOR ARGUMENT {{term['name']}},.
          {% endif %}
       {%- endfor %}
    ]),
    % At least one parameter should be passed in the request URL.
    ((
    {%- for key in term['arguments'] %}
     var({{key|capitalize}}){% if not loop.last %},{% else %} -> {% endif %}
    {%- endfor %}
    prolog_to_json(failure, JSONOut),
    reply_json(JSONOut, [status(409)]));
    
    list_{{term['name']}}(_{{'{'}}{% for key in term['arguments'] %}{{key | lower }}:{{key | capitalize }}{% if not loop.last %}, {% endif %}{% endfor %}{{'}'}}, L),
    reply_json_dict(_{result:L}, [status(200)])
    ).
 {%- endcall %}
{# DELETE method for each dynamic predicate.
  example: delete_person(_{name:Name, age:Age}) :- retract(person(Name, Age)).
#} 
% DELETE method for each dynamic predicate.
{%- call(term) macros.facts_handlers(data) %}
delete_{{term['name']}}(_{{'{'}}{% for key in term['arguments'] %}{{key | lower }}:{{key | capitalize }}{% if not loop.last %}, {% endif %}{% endfor %}{{'}'}}) :- retract({{term['name']}}({% for key in term['arguments'] %}{{key | capitalize }}{% if not loop.last %}, {% endif %}{% endfor %})). 
{%- endcall %}

% Handle DELETE requests with parameters  in URL
{%- call(term) macros.facts_handlers(data) %}
handle_{{term['name']}}_delete(Request) :- 
    http_parameters(Request,
    [
        {%- for key in term['arguments'] %}
          {%- if term['arguments'][key]['type'] == 'string' %}
     {{key | lower}}({{key | capitalize}}, [optional(false)]){% if not loop.last %}, {% endif %}
          {%- elif term['arguments'][key]['type']  == 'number' %}
     {{key | lower}}({{key | capitalize}}, [number, optional(false)]){% if not loop.last %}, {% endif %}
          {%- else %}
     UNKNOWN DATA TYPE FOR ARGUMENT {{term['name']}},.
          {% endif %}
       {%- endfor %}
    ]),
    delete_{{term['name']}}(_{{'{'}}{% for key in term['arguments'] %}{{key | lower }}:{{key | capitalize }}{% if not loop.last %}, {% endif %}{% endfor %}{{'}'}}) ->
    prolog_to_json(success, JSONOut),
    reply_json(JSONOut, [status(200)]);
    prolog_to_json(failure, JSONOut),
    reply_json(JSONOut, [status(403)]).    
{%- endcall %}

{% call(term) macros.rules_handlers(data) %}
list_{{term['name']}}(_{{'{'}}{% for key in term['arguments'] %}{{key | lower }}:{{key | capitalize }}{% if not loop.last %}, {% endif %}{% endfor %}{{'}'}},L):- findall(_{{'{'}}{% for key in term['arguments'] %}{{key | lower }}:{{key | capitalize }}{% if not loop.last %}, {% endif %}{% endfor %}{{'}'}}, {{term['name']}}({% for key in term['arguments'] %}{{key | capitalize }}{%if not loop.last %},{% endif %}{% endfor %}), L).
{% endcall %}

{% call(term) macros.rules_handlers(data) %}
handle_request_{{term['name']|lower}}(Request) :-
   http_parameters(Request,
    [
        {%- for key in term['arguments'] %}
          {%- if term['arguments'][key]['type'] == 'string' %}
     {{key | lower}}({{key | capitalize}}, [optional(true)]){% if not loop.last %}, {% endif %}
          {%- elif term['arguments'][key]['type']  == 'number' %}
     {{key | lower}}({{key | capitalize}}, [number, optional(true)]){% if not loop.last %}, {% endif %}
          {%- else %}
     UNKNOWN DATA TYPE FOR ARGUMENT {{term['name']}},.
          {% endif %}
       {%- endfor %}
    ]),
    list_{{term['name']}}(_{{'{'}}{% for key in term['arguments'] %}{{key | lower }}:{{key | capitalize }}{% if not loop.last %}, {% endif %}{% endfor %}{{'}'}},L) ->
    reply_json_dict(_{result:L});
    prolog_to_json(failure, JSONOut),
    reply_json(JSONOut).
{% endcall %}

server(Port) :-
    http_server(http_dispatch, [port(Port)]).

:- initialization(server(8000)).

