Red []
do %table.red
sql: func ['query /tabulate format][
	if string? query [query: rejoin [{"} query {"}]] 
	call/output rejoin [{sqlite } query] out: clear "" 
	if out [
		rows: 1
		out: replace/all out "^^M" "" 
		out: load out
		if integer? first out [
			rows: take out
			if block? first out [out: first out]
		]
		cols: (length? out) / rows
		either tabulate [
			table/colors format out [snow white]
		][out]
	]
]
