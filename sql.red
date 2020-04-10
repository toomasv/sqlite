Red []
do %../table/table.red
sql: func ['query][
	if string? query [query: rejoin [{"} query {"}]] 
	call/output probe rejoin [{sqlite } query] out: clear "" 
	if out [
		out: replace/all out "^^M" "" 
		load out
	]
]
