Red [
	Needs: View
]
#include %SQLite3.red
#include %diagram-style.red
;#include %../table/table.red

result: make block! 100

SQLite/do [
	db1: open %chinook.db
	use :db1
]
ws: charset " ^-^/"
ws+: [some ws]
ws*: [any ws]
fk: make block! 50
tnames: make block! 50
current-db: none

extract-tables: does [extract SQLite/query {SELECT name FROM sqlite_master WHERE type='table' and name not like 'sqlite_%'} 1]
tables: extract-tables
databases: collect [foreach f read %. [if %.db = suffix? f [keep to-string first split f/1 dot]]]
change-data: func [/local fields tbl][
	if not tbls/selected [tbls/selected: 1]
	case [
		dbs/data []
		tbls/selected > 0 [
			rels/visible?: no
			tbl: pick tbls/data tbls/selected
			res/text: case [
				data/data [
					mold/only probe SQLite/query rejoin ["SELECT * FROM " tbl]
				]
				schm/data [
					first SQLite/query rejoin ["SELECT sql FROM sqlite_master WHERE name='" tbl "'"]
				]
				flds/data [
					fields: SQLite/query rejoin ["PRAGMA table_info('" tbl "')"]
					mold/only new-line/all extract at probe fields 2 6 true
				]
			]
			;query/text: form SQLite/cols
		]
	]
]
change-db: does [
	print dbfile: to-file append copy pick db/data db/selected ".db"
	SQLite/do probe compose [
		close :db1
		db1: open (dbfile)
		use :db1
	]
	append clear tables extract-tables
	tbls/selected: 1;-1
	change-data
	;clear res/text
]
reconnect: function [node][
	if c: node/options/to [
		foreach d c [
			unless d/options/shape/1 = 'blank [
				l: find/tail d/draw 'line 
				l/1: node/offset + (node/size / 2)
			]
		]
	]
	if c: node/options/from [
		foreach d c [
			unless d/options/shape/1 = 'blank [
				l: find/tail d/draw 'line 
				l/2: node/offset + (node/size / 2)
			]
		]
	]
]
db-view: has [tbl name fields t1 f1 f2 t2][
	if dbs/data [
		;system/view/auto-sync?: off
		clear rels/pane
		clear fk
		clear tnames
		result: SQLite/query {SELECT sql FROM sqlite_master WHERE type='table' and name not like 'sqlite_%'}
		;res/text: mold 
		print result ;: extract at result 2 2
		foreach tbl result [
			fields: parse tbl [
				collect [
					"CREATE TABLE " ws* opt dbl-quote copy name to [dbl-quote | ws | #"("]
					thru [#"(" ws*]
					some [
						;opt comma ws* opt #"[" keep to [#"]" | ws+] to [comma | "FOREIGN KEY" | end]
						#"[" keep to #"]"
					|	ahead "FOREIGN KEY" some [
							"FOREIGN KEY ([" copy f1 to "])" 
							thru {REFERENCES "} copy t2 to {"} 
							thru "([" copy f2 to "])" 
							to ["FOREIGN KEY" | end];[comma ws+ | #")"]
							(repend fk [name f1 t2 f2])
						]
						thru end
					|	skip
					]
				]
			]
			len: max 100 16 * length? fields
			append tnames name
			append rels/pane layout/only compose/deep [
				text-list loose extra name data fields with [size/y: len]
				on-drag [reconnect face]
			]
		]
		conns: tail rels/pane
		foreach [t1 f1 t2 f2] fk [
		;while [set [t1 f1 t2 f2] take/part fk 4] [
			if all [
				t1: find tnames t1
				t2: find tnames t2
			][
				t1: rels/pane/(index? t1)
				t2: rels/pane/(index? t2)
				i1: index? find t1/data f1
				i2: index? find t2/data f2
				append rels/pane lst: layout/only compose/deep dia [
					connect line 
						from [top-right (as-pair 0 i1 - 1 * 16 + 8) (t1)] 
						to [top-left (as-pair 0 i2 - 1 * 16 + 8) (t2)]
				]
				unless t1/options/to [put t1/options 'to make block! 10]
				append t1/options/to lst
				unless t2/options/from [put t2/options 'from make block! 10]
				append t2/options/from lst
			]
		]
		move/part conns rels/pane length? conns
		rels/visible?: yes
		;print "2"
		;show rels/parent
		;print "3" system/view/auto-sync?: on
	]
]
view/options/flags [
	below
	btn: button 110 "Do" [
		result: SQLite/query query/text
		either empty? result [
			change-data
		][
			res/text: mold/only probe result
		]
	] pad 0x-5
	pan: panel [
		origin 0x0
		data: radio 40 "data" data true on-change [change-data]
		schm: radio 60 "schema" on-change [change-data] return
		pad 0x-10
		dbs:  radio 40 "dbs" on-change [db-view]
		
		flds: radio 60 "fields" on-change [change-data]
	] return
	query: area 500x75 wrap 
	pad -120x0 
	db: drop-down 110 data databases select 1 on-change [change-db db-view] on-enter [print db/text]
	across tbls: text-list 110x465 data tables select 1 on-change [change-data]
	pad 0x-35 res: area 500x500 
	at 0x0 rels: panel hidden []
	do [rels/offset: res/offset change-data]
][
	actors: object [
		ofs: none
		on-down: func [face event][
			ofs: event/offset
		]
		on-over: func [face event][
			if event/down? [
				df: event/offset - ofs
				case/all [
					within? event/offset query/offset - 10x0 as-pair 10 face/size/y - 20 [
						btn/size/x: pan/size/x: db/size/x: tbls/size/x: btn/size/x + df/x
						query/offset/x: res/offset/x: rels/offset/x: query/offset/x + df/x
						query/size/x: res/size/x: rels/size/x: query/size/x - df/x
						foreach-face/with rels [face/size: rels/size][face/type = 'base]
					]
					within? event/offset res/offset - 0x10 as-pair res/size/x 10 [
						query/size/y: query/size/y + df/y
						res/offset/y: rels/offset/y: query/size/y + 20; + df/y
						res/size/y: rels/size/y: res/size/y - df/y
						foreach-face/with rels [face/size: rels/size][face/type = 'base]
					]
				]
				ofs: event/offset
			]
		]
		on-resizing: func [face event][
			res/size/x: query/size/x: face/size/x - query/offset/x - 10
			res/size/y: face/size/y - res/offset/y - 10
			tbls/size/y: face/size/y - tbls/offset/y - 10
			rels/size: res/size
			foreach-face/with rels [face/size: rels/size][face/type = 'base]
		]
	]
][resize all-over]

clear result 

SQLite/free