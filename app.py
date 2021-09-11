import os
import json
from os import listdir
from os.path import isfile, join
from jinja2 import Environment, FileSystemLoader
import inflect

p = inflect.engine()

templates_folder = './templates/'
input_folder = './input/'
serveur_template_file = 'app.tpl'
home_page_template_file = 'home_page.tpl'

def load_file(_file):
   with open(_file,'r') as fp:
     r = fp.read()
   return r

ll = []
# Load the input files (json).
for name in os.listdir(input_folder) :
  if name.endswith('.json'):
     ll.append(json.loads(load_file(input_folder+name)))

# json boolean values are true and false, they need to be changed to Python True and False.
# We also add the plural of each fact.
for item in ll:
  item['name'] = item['name'].lower()
  item['isFact'] = (item['isFact'] == True)
  if item['isFact']:
    if p.singular_noun(item['name']): 
        item['plural'] = "all_" + item['name']
    else:
        item['plural'] = p.plural(item['name'])
  

env = Environment(loader=FileSystemLoader(templates_folder))
template = env.get_template(serveur_template_file)
dest = 'app.pl'
with open(dest,"w") as fh:
  fh.write(template.render(data=ll))
  
 
############ We generate the html home page ########################

env = Environment(loader=FileSystemLoader(templates_folder))
template = env.get_template(home_page_template_file)
dest = 'home_page.pl'
with open(dest,"w") as fh:
  fh.write(template.render(data=ll))


 

