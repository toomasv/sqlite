Red [
	Needs: View
]
#include %SQLite3.red

result: make block! 100

SQLite/do [
	db1: open %chinook.db
	use :db1
]

current-db: none

extract-tables: does [new-line/all SQLite/query {SELECT name FROM sqlite_master WHERE type='table' and name not like 'sqlite_%'} true]
databases: new-line/all collect [foreach f read %. [if %.db = suffix? f [keep to-string first split f/1 dot]]] true
change-db: func [dbfile][
	SQLite/do probe compose [
		close :db1
		db1: open (dbfile)
		use :db1
	]
	extract-tables
]

if not empty? args: load/all system/script/args [
	either string? qry: first args [
		probe SQLite/query qry
	][
		switch first args [
			change-db [do args]
			.databases [probe length? databases probe databases]
			.tables [probe extract-tables]
			.schema [
				print mold/only SQLite/query rejoin ["SELECT sql FROM sqlite_master WHERE name='" second args "'"]
			]
			.fields [
				fields: SQLite/query rejoin ["PRAGMA table_info('" second args "')"]
				print mold/only new-line/all extract at fields 2 6 true
			]
			.data [
				print mold/only SQLite/query rejoin ["SELECT * FROM " second args]
			]
			true [probe SQLite/do args]
		]
	]
]

clear result 

SQLite/free