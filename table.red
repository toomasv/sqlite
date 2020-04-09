Red []
table: function [
	{Formats block of strings into table}
	format [block!] 		{Block of formats for each column}
	data [block!] 			{Block of strings to format, if there is block instead of 
							 string it is interpreted as cell with special format}
	/size sz [integer!] 	{Table width, default 700}
	/head th [block!]		{Table has head with common format. 
							 (`th` e.g [gray white bold ["Col1" "Col2" [right "Col3"]]])}
	/tight 					{Default width is ignored, size is calculated from cells}
	/colors clrs [block!]	{Block of alternating colors for rows}
	/default def [block! word! integer!]
][
	default-size: 700
	styles: make block! 10
	cols: make block! 10
	widths: make block! 10
	free-widths: make block! 10
	heights: make block! 50
	body: copy []
	texts: copy []
	special: make block! 10
	unsized: height: 0
	row: 1
	get-size: func [c][either widths/:c [as-pair widths/:c 20][1000x20]]
	extend system/view/VID/styles [
		cell: [template: [type: 'base color: white para: make para! [wrap?: yes]]]
		arrows: [
			template: [
				type: 'base
				color: 0.0.0.254
				draw: copy []
				actors: [
					ofs: line: none
					;on-created: func [f e][probe "hu"]
					on-down: func [face event][
						ofs: event/offset
						append event/face/draw compose [line: line (ofs) (ofs)]
					]
					on-over: func [face event][
						line/3: event/offset
					]
				]
			]
			;init: [
			;	at-offset: 0x0
			;	face/flags: 'all-over
			;]
		]
	]
	view/no-wait layout/options [
		default: panel [] 
		head-style: panel []
		style: panel [] 
		special-style: panel [] 
	][visible?: no]
	;view/no-wait special-style: layout/options [][visible?: no]
	if def [insert default/pane append copy [cell] def]
	if head [
		heads: take find th block!
		;view/no-wait head-style: layout/options [][visible?: no]
		insert head-style/pane layout/only append copy [cell] th
	]
	forall format [
		if width: case [
			integer? format/1 [also format/1 format/1: as-pair format/1 1]
			pair? format/1 [format/1/x]
			block? format/1 [
				case [
					w: find format/1 pair! [w/1/x] 
					w: find format/1 integer! [also w/1 w/1: as-pair w/1 1]
				]
			]
			true [unsized: unsized + 1 none]
		]
		append widths width
		append cols word: to-word rejoin ["col" index? format]
		append styles sty: compose [style (to-set-word word) cell (format/1)]
		append style/pane layout/only at sty 3 
	]
	len-cols: length? cols
	if size [default-size: sz]
	if all [not tight unsized > 0] [
		auto-size: default-size / unsized
		replace/all widths none auto-size
	]
	forall data [
		c: (index? data) - 1 % len-cols + 1
		r: (index? data) - 1 / len-cols + 1
		sp-st: no
		txt: switch/default type?/word data/1 [
			string! [data/1]
			block! [
				txt: either txt: find data/1 string! [take txt][copy ""]
				append special-style/pane layout/only append copy [cell] first data
				sp-st: yes
				repend special [r c data/1 sp-pane: back tail special-style/pane]
				sp-pane/1/size: get-size c
				txt
			]
		][form data/1]
		style/pane/:c/size: get-size c
		text-size: size-text/with either sp-st [sp-pane/1][style/pane/:c] txt
		;print [txt text-size]
		unless widths/:c [
			put free-widths c either fw: select free-widths c [ 
				max fw text-size/x
			][
				text-size/x
			] 
		]
		height: either row = r [
			max height text-size/y
		][
			row: r 
			append heights height
			0
		]
		append texts txt
	]
	append heights height
	if c < len-cols []
	row: 1
	forall texts [
		c: (index? texts) - 1 % len-cols + 1
		r: (index? texts) - 1 / len-cols + 1
		found: find/tail special reduce [r c]
		td: reduce [
			either found ['cell][cols/:c] texts/1 either widths/:c [
				as-pair widths/:c heights/:r
			][
				as-pair select free-widths c heights/:r
			]
		]
		if all [colors any [not th r > 1]][append td clrs/(r - 1 % (length? clrs) + 1)]
		if row <> r [row: r insert td 'return]
		if found [append td found/1]
		append body td
	]
	unview/all
	;system/view/metrics/margins/base: [3x0 0x3]
	
	view compose/deep [
		panel gray [
			across
			origin 1x1 space 1x1
			(styles) 
			(body)
			;arrows
			at 0x0 arr: box 182x105 0.0.0.254 ;react [face/size: face/parent/size]
				draw [pen blue] 
				on-down [
					append face/draw compose/deep [
						line (quote (ofs: event/offset)) (quote (ofs)) transform 0x0 0 1 1 (quote (ofs)) [shape [move -4x-2 'line 4x2 -4x2 move -10x5]]
					]
					line: skip tail face/draw -10
				]
				all-over on-over [if event/down? [
					line/3: line/9: event/offset 
					diff: line/3 - line/2
					line/6: arctangent2 diff/y diff/x
					
				]];probe
			;button [? arr]
		]
		do [arr/size: arr/parent/size]
	]
]
comment {
probe files: read %.
texts: copy []
foreach file files [probe modified: query file append texts reduce [mold file modified/date rejoin [modified/hour ":" modified/minute]]]
table/tight/colors/head [[] [center beige] [right]] append [[gray white "File"] [gray white "Date"] [gray white "Time"]] texts [silver white] [silver]
}
comment {
view [panel black [origin 1x1 space 1x1 
    style c: text wrap center white 50x32 
    c bold "Row 1" c "Cell 1.2" c "Cell 1.3" c "Longer text" return 
    c bold "Row 2" c "Cell 2.2" c "Cell 2.3" c "Cell 2.4"
]]
}