#!/usr/bin/env bash

#This is a draft script for adding the COUCHDB_URL environment variable
#Note that this assumes that the line "  only_item(vcap_services['mysql']) do |s|" exists
#and that it is preceded by an empty line.

#set the expression to find in services_env.rb
FINDME="\\ *only_item\\(vcap_services\\[\\'mysql\\'\\]\\)\\ *do[\\ ]*\\|s\\|"

#find the line preceding the findme pattern
LINE=`awk '/'"$FINDME"'/{print NR - 1}' /s/vcap/common/lib/vcap/services_env.rb`

#set replacement lines
NEW_LINE1="\n\\ \\ \\ \\ only_item\\(vcap_services\\[\\'couchdb\\'\\]\\)\\ do\\ \\|s\\|\n"
NEW_LINE2="\\ \\ \\ \\ \\ \\ c\\ =\\ s\\[:credentials\\]\n"
NEW_LINE3="\\ \\ \\ \\ \\ \\ e\\[\\\"COUCHDB_URL\\\"\\]\\ \\=\\ \\\"\\#\\{c\\[:couchdb_url\\]\\}\\\"\n"
NEW_LINE4="\\ \\ \\ \\ end\n"

#insert the new lines to services_env.rb
sed -i ''"$LINE"'s/.*/'"$NEW_LINE1$NEW_LINE2$NEW_LINE3$NEW_LINE4"'/' /s/vcap/common/lib/vcap/services_env.rb

