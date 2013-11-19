#!/usr/bin/env bash

cd $(dirname $0)

echo "Please enter cloud controller api url (api.stackato.local): "
read CCURL

stackato target $CCURL
stackato login
stackato services

sleep 3

stackato create-service couchdb task-db-extra

git clone https://github.com/jhou2/tasks
pushd tasks
	stackato push -n todo-list-1
	stackato push -n todo-list-2

	sleep 3

	stackato bind-service task-db-extra todo-list-1
	stackato bind-service task-db-extra todo-list-2

	sleep 3

	stackato unbind-service task-db-extra todo-list-1
	stackato unbind-service task-db-extra todo-list-1

	stackato open todo-list-1
	stackato open todo-list-2

	sleep 10

	stackato delete todo-list-1
	stackato delete todo-list-2
popd
rm -rf tasks
stackato delete-service task-db-extra



