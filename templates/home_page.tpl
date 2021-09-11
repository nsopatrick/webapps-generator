:- module(home_page, [display_home_page/1]).
:- encoding(utf8).

display_home_page(_Request) :-
    format('Content-type: text/html~n~n'),
    format('
<html>
   <head>
      <title>
         Générateur d’application Web - API REST
      </title>
   </head>
   <body>
         <h1>
            Générateur d’application Web - API REST
         </h1>
         <h3>
         Documentation
         </h3>
      <table style="border-collapse: collapse; width: 100%;" border="1">
	<tbody>
	<tr>
	<td style="width: 10%; text-align: center;"><strong>Method</strong></td>
	<td style="width: 25%; text-align: center;"><strong>Endpoint</strong></td>
	<td style="width: 65%; text-align: center;"><strong>Description</strong></td>
	</tr>
	{%- for item in data %} 
	{%- if item['isFact']%}
	<tr bgcolor="#ddd">
	<td style="width: 10%;">POST</td>
	<td style="width: 25%;">/{{item['name']|lower}}</td>
	<td style="width: 65%;">Create a new {{item['name']|lower}}</td>
	</tr>
	<tr>
	<td style="width: 10%;">GET</td>
	<td style="width: 25%;">/{{item['name'|lower]}}/ask</td>
	<td style="width: 65%;">Search for a/an {{item['name']|lower}} using the following criteria: {% for key in item['arguments'] %}{{key | lower }}{% if not loop.last %}, {% endif %}{%- endfor %} 
	</td>
	</tr>
	<tr>
	<td style="width: 10%;">DELETE</td>
	<td style="width: 25%;">/{{item['name']|lower}}/del</td>
	<td style="width: 65%;">Delete a/an {{item['name']|lower}}</td>
	</tr>
	<tr>
	<td style="width: 10%;">GET</td>
	<td style="width: 25%;">/{{item['plural']|lower}}</td>
	<td style="width: 65%;">List all {{item['plural']|lower}}</td>
	</tr>
	{%- endif %}
	{%- endfor %}
	<tr bgcolor="#ddd">
	<td style="width: 10%;"> &nbsp;</td>
	<td style="width: 25%;"> &nbsp;</td>
	<td style="width: 65%;"> &nbsp;</td>
	</tr>
	{%- for item in data %} 
	{%- if not item['isFact']%}
	<tr>
	<td style="width: 10%;">GET</td>
	<td style="width: 25%;">/requests/{{item['name']|lower}}</td>
	<td style="width: 65%;">List the elements that satisfy &#8216;{{item['name']|lower}}&#8217;. {{item['name']|lower}}&#8216;s arguments: {% for key in item['arguments'] %}{{key | lower }}{% if not loop.last %}, {% endif %}{%- endfor %}</td>
	</tr>
	{%- endif %}
	{%- endfor %}
	</tbody>
	</table>
   </body>
</html>
').
    
    
    

