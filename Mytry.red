Red [
	Needs: View
]
#include %SQLite3.red

result: make block! 32

SQLite/do [
	db1: open %mytest.db
	use   :db1
]

view [
	below 
	query: area 500 wrap
	pad 170x0 button "Query" [
		result: SQLite/query query/text
		res/text: form result
	] 
	button "Do" [
		result: SQLite/do load query/text
		res/text: form result
	] 
	pad -200x0 res: area 500x500
]

clear result 

SQLite/free