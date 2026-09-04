	package require Tk


	set w ""

	wm title . "Sudoku 1.4"
	wm iconname . "sudoku"

	if { [winfo exist .buttons] == 0 } {

	frame $w.buttons
	pack $w.buttons -side bottom -fill x -pady 2m
	button $w.buttons.open -text Open -command "sdkfile open"
	button $w.buttons.solve -text Solve -command "trysudoku"
	button $w.buttons.save -text Save -command "sdkfile save"
	button $w.buttons.dismiss -text Dismiss -command "destroy ."
	pack $w.buttons.open $w.buttons.solve $w.buttons.save \
	$w.buttons.dismiss -side left -expand 1

	}

	proc styles  {} {

		global w

		$w.text tag configure norm -font {Courier 14}
		$w.text tag configure big -font {Courier 14 bold}
		$w.text tag configure color1 -background #a0b7ce
		$w.text tag configure color2 -foreground red
	}

	set filename ""

# livello medio
	set filename1 "medio.sdk"
	set sudoku1 {	{0 6. 4. 2. 3. 0 0 8. 0}
			{0 0 5. 0 0 8. 1. 0 0}
			{0 7. 3. 0 6. 0 0 0 5.}
			{0 0 8. 0 0 0 0 4. 6.}
			{5. 0 0 0 0 0 0 0 7.}
			{9. 1. 0 0 0 0 2. 0 0}
			{7. 0 0 0 4. 0 3. 9. 0}
			{0 0 2. 7. 0 0 6. 0 0}
			{0 5. 0 0 1. 2. 8. 7. 0}}

# livello avanzato
	set filename2 "avanzato.sdk"
	set sudoku2 {	{0 0 1. 0 0 7. 4. 0 0}
			{4. 5. 0 0 0 0 0 7. 1.}
			{0 2. 0 0 3. 0 0 9. 0}
			{6. 0 0 0 0 0 0 0 0}
			{0 0 8. 9. 0 1. 3. 0 0}
			{0 0 0 0 0 0 0 0 7.}
			{0 3. 0 0 4. 0 0 2. 0}
			{1. 4. 0 0 0 0 0 6. 5.}
			{0 0 9. 8. 0 0 7. 0 0}}

# livello esperto
	set filename3 "esperto.sdk"
	set sudoku3 {	{0 0 5. 0 0 0 4. 0 0}
			{0 8. 0 0 6. 0 0 9. 0}
			{2. 0 0 0 5. 0 0 0 7.}
			{0 0 0 9. 0 0 0 0 0}
			{0 1. 4. 0 0 0 8. 5. 0}
			{0 0 0 0 0 3. 0 0 0}
			{6. 0 0 0 7. 0 0 0 3.}
			{0 5. 0 0 8. 0 0 1. 0}
			{0 0 9. 0 0 0 2. 0 0}}

# livello devil
	set filename4 "devil.sdk"
	set sudoku4 {	{0 0 0 0 0 9. 0 0 0}
			{7. 0 0 5. 0 3. 0 0 2.}
			{0 0 5. 0 0 1. 9. 0 0}
			{8. 6. 3. 0 0 4. 0 9. 0}
			{0 0 0 0 7. 0 0 0 0}
			{0 7. 0 3. 0 0 1. 4. 8.}
			{0 0 9. 4. 0 0 5. 0 0}
			{2. 0 0 6. 0 5. 0 0 7.}
			{0 0 0 8. 0 0 0 0 0}}

# livello diabolico due
	set filename5 "diabolico.sdk"
	set sudoku5 {	{0 0 0 9. 0 0 0 5. 0}
					{0 0 0 0 8. 0 7. 0 0}
					{0 0 3. 0 5. 0 9. 1. 8.}
					{0 0 0 3. 0 0 0 0 9.}
					{9. 4. 0 0 0 0 0 6. 1.}
					{8. 0 0 0 0 1. 0 0 0}
					{3. 9. 5. 0 6. 0 8. 0 0}
					{0 0 7. 0 3. 0 0 0 0}
					{0 6. 0 0 0 5. 0 0 0}}

# livello TRUE devil				
	set filename6 "TRUE devil.sdk"
	set sudoku6 {	
	{3. 0 5. 6. 0 0 0 0 0}
	{0 0 6. 0 0 4. 9. 5. 0}
	{0 4. 0 8. 0 0 0 0 3.}
	{4. 0 3. 0 0 0 0 1. 0}
	{ 0 0 0 0 0 0 0 0 0}
	{0 6. 0 0 0 0 7. 0 9.}
	{5. 0 0 0 0 2. 0 3. 0}
	{0 3. 7. 1. 0 0 8. 0 0}
	{0 0 0 0 0 9. 1. 0 2.}}


# livello zero
	set filename0 "zero.sdk"
	set sudoku0 {	{0 0 0 0 0 0 0 0 0}
			{0 0 0 0 0 0 0 0 0}
			{0 0 0 0 0 0 0 0 0}
			{0 0 0 0 0 0 0 0 0}
			{0 0 0 0 0 0 0 0 0}
			{0 0 0 0 0 0 0 0 0}
			{0 0 0 0 0 0 0 0 0}
			{0 0 0 0 0 0 0 0 0}
			{0 0 0 0 0 0 0 0 0}}

	proc upsudoku { } {

		global w sudoku filename sdkId
		global magic branchid whichproc nextproc tryrowcol

		incr sdkId
		upvar sudoku$sdkId up_sudoku
		upvar filename$sdkId up_filename

		if [info exist up_sudoku] {

		} else {

			set sdkId 0

			upvar sudoku$sdkId up_sudoku
			upvar filename$sdkId up_filename
		}

		set sudoku $up_sudoku
		set filename $up_filename
		
		newtext $up_filename

			$w.buttons.solve configure -state normal -text " Solve " -command "trysudoku"

			array set magic ""
			set branchid 0
			set whichproc 1
			set nextproc  0
			set tryrowcol 1

	}

	bind . <Control-n> {upsudoku}

	proc issudoku { } {

		global sudoku

		set zeri 0

		for { set j 0 } { $j<9 } {incr j} {
			for { set i 0 } { $i<9 } {incr i} {

##		puts "## --[lindex \
##			 [lindex $sudoku $i] $j]--"
##		puts "## maybe $i,$j = [maybe $i $j [lindex \
##			 [lindex $sudoku $i] $j]]"

			set trueij [lindex [lindex $sudoku $i] $j]
			## puts "## trueij=$trueij"
			set ij [string index $trueij 0]
			## puts "##     ij=$ij"
			if { $ij > 0 } {

##			puts "## ($i,$j) := 0"
				newij $i $j 0 0

				if { [maybe $i $j $ij] == -1 } {
				
					puts "bad: ($i,$j)=$ij <$trueij>"
					return -1
				}

				newij $i $j $trueij 0

			} else {

				incr zeri
			}
			}
		}

		return $zeri
	}

	proc newij { i j value {wrt 1} } {

		global sudoku

		set tmp [lreplace [lindex  $sudoku $i] $j $j $value]

		set sudoku [lreplace $sudoku $i $i $tmp]

		if { $wrt } { writeij $i $j $value }

		return $value
	}

	proc iszero { i j } {

		global sudoku

		if { [lindex [lindex $sudoku $i] $j] != 0 } {

			return -1

		} else {

			return 0
		}
	}

	proc isinline { line value {colonna -1} } {

		global sudoku

		for { set j 0 } { $j<9 } {incr j} {

			set ij [lindex [lindex $sudoku $line] $j]
			## puts "($line,$j) $ij"

			## puts "exact =[lsearch -exact $ij $value]"
			if { [lsearch -exact $ij $value] != -1 } {

			return $j
			}

			##puts "regexp =[lsearch -regexp $ij ",$value"]"
			if { [lsearch -regexp $ij ",$value"] != -1 } {

			set minj [expr ($colonna/3)*3]
			set maxj [expr ($minj+3)]

			if { (($j>=$minj) && ($j<=$maxj)) } {

				# puts ">>>> j=$j !$minj-$maxj! ij=$ij <<<<< ,,,,,"
				return -1

			} else {

				# puts ">>>> j=$j ij=$ij <<<<<"
				return $j
			}
			}
		}

		return -1
	}

	proc isincoloumn { coloumn value {riga -1} } {

		global sudoku

		for { set i 0 } { $i<9 } {incr i} {

			set ij [lindex [lindex $sudoku $i] $coloumn]

			if { [lsearch -exact $ij $value] != -1 } {

			return $i
			}

			if { [lsearch -regexp $ij ";$value"] != -1 } {

			set mini [expr ($riga/3)*3]
			set maxi [expr $mini+3]

			if { (($i>=$mini) && ($i<=$maxi)) } {

				# puts ">>>> i=$i !$mini-$maxi! ij=$ij <<<<< ;;;;;"
				return -1

			} else {
				# puts ">>>> i=$i ij=$ij <<<<<"
				return $i
#		}
			}
		}

		return -1
	}

	proc isinrange { ri rj value } {

		global sudoku

		set mini [expr ($ri/3)*3]
		set maxi [expr $mini+3]
		## puts "## mini=$mini maxi=$maxi"

		set minj [expr ($rj/3)*3]
		set maxj [expr ($minj+3)]
		## puts "## minj=$minj maxj=$maxj"

		for { set j $minj } { $j<$maxj } {incr j} {
		for { set i $mini } { $i<$maxi } {incr i} {

			set ij [lindex [lindex $sudoku $i] $j]

			## puts -nonewline "($i,$j)=$ij value=$value"
			if { [string index $ij 0] == $value } {

				return "$i,$j"
			}
		}}
		return -1
	}

	proc maybe { i j value } {

		global sudoku

		if { $value == 0 } {

			newij $i $j 0

			return 0
		}

		if { [lindex [lindex $sudoku $i] $j] == $value } {

##		puts "## $i,$j := $value"
##		newij $i $j 0

			return -1
		}

		if { [isinline $i $value $j] != -1 } {

			return -1
		}
		if { [isincoloumn $j $value $i] != -1 } {

			return -1
		}
		if { [isinrange $i $j $value] != -1 } {

			return -1
		}

		return $value

##	newij $i $j $value
	}


	proc maylist { i j } {

		set trylist ""

		for { set may 1 } { $may<10 } {incr may} {

			set try [maybe $i $j $may]

			## if { $try > 0 } { puts -nonewline " $try" }

			if { $try > 0 } { lappend trylist $try }
		}
		##puts ""

		return $trylist
	}

	proc allrowcoloums {} {

		global sudoku magic
		global w

		puts "rowcoloums:"

		if { [array exist magic] } { unset magic }

		set how 0

		for { set i 0 } { $i<9 } {incr i} {
			for { set j 0 } { $j<9 } {incr j} {

				set ij [lindex [lindex $sudoku $i] $j] 

				if { [lsearch -regexp $ij 0] == 0 } {

					set tags "$i,$j"
					$w.text tag configure $tags -background yellow
					update idletasks

					set trylist [maylist $i $j]

					puts "($i,$j) $trylist "
		
					# puts -nonewline "($i,$j) "
					# puts -nonewline "[maylist $i $j]"
					# puts ""

					if { [llength $trylist] == 1 } {

						incr how

						newij $i $j $trylist
						puts "($i,$j) $trylist"

					} else {

##					set magic($i,$j) [llength $trylist]
					}

					$w.text tag configure $tags -background {}
					update idletasks
				}
			}
		}

		return $how
	}

	proc tryrange { ri rj } {

		global sudoku magic
		global w

		set how 0

		set mini [expr ($ri/3)*3]
		set maxi [expr $mini+3]

		set minj [expr ($rj/3)*3]
		set maxj [expr ($minj+3)]

		## puts "## $mini,$maxi $minj,$maxj"

		set tags "$ri-$rj"
		$w.text tag configure $tags -background #a0b7ce
		update idletasks

		for { set i $mini } { $i<$maxi } {incr i} {

			for { set j $minj } { $j<$maxj } {incr j} {

			set ij [lindex [lindex $sudoku $i] $j] 

			if { [lsearch -regexp $ij 0] == 0 } {

				set trylist [maylist $i $j]

				puts "($i,$j) $trylist"
				set magic($i,$j) $trylist

				incr how
			}
			}
		}

		after 100
#	$w.text tag configure $tags -background {}

		if { (($ri == 0) || ($ri == 6)) &&
			 (($rj == 0) || ($rj == 6)) ||
			 (($ri == 3) && ($rj == 3)) } {

			$w.text tag configure $tags -background #eee
		
		} else {

			$w.text tag configure $tags -background {}

		}

		update idletasks
		return $how
	}

	proc whichrange { ri rj } {

		global sudoku magic

		set news 0

		for { set may 1 } { $may<10 } {incr may} {

			set how 0

			set which ""

			## puts "## may $may"

			set arraynames ""

			for { set j $rj } { $j<$rj+3 } {incr j} {
			for { set i $ri } { $i<$ri+3 } {incr i} {

			lappend arraynames "$i,$j"
			}}

			## puts "## arraynames <$arraynames>"
			foreach id $arraynames {

			if { [info exist magic($id)] } {

			## puts "lsearch [lsearch -exact $magic($id) $may]"

			if { [lsearch -exact $magic($id) $may] > -1} {

				incr how

				set where $id
			}
			}
			}

			## puts "##  how $how"

			if { $how == 1 } {

			## puts "($where) $may"
			set i [lindex [split $where ,] 0]
			set j [lindex [split $where ,] 1]

			set ij [lindex [lindex $sudoku $i] $j] 

			if { [string index $ij 0] == 0 } {

				puts "($i,$j) $may"
				newij $i $j $may

				incr news
			}
			}
		}

		return $news
	}


	proc allranges {} {

		global magic

		puts "ranges:"

		if { [array exist magic] } { unset magic }

		set how 0

		for { set i 0 } { $i<9 } {incr i 3} {
			for { set j 0 } { $j<9 } {incr j 3} {

				if { [tryrange $i $j] > 0 } {

					incr how [whichrange $i $j]
				}
			}
		}

		return $how
	}

	proc whichrowcol { ri rj } {

		global sudoku magic
		global w

		puts "rowcol:"

		set news 0

		for { set may 1 } { $may<10 } {incr may} {


			## puts "## may $may"

			for { set j $rj } { $j<$rj+3 } {incr j} {
			for { set i $ri } { $i<$ri+3 } {incr i} {

				set row($i) 0
				set col($j) 0
			}}

			for { set j $rj } { $j<$rj+3 } {incr j} {
			for { set i $ri } { $i<$ri+3 } {incr i} {

			set id "$i,$j"

			if { [info exist magic($id)] } {

				##puts "lsearch [lsearch -exact $magic($id) $may]"

				if { [lsearch -exact $magic($id) $may] > -1} {

				incr row($i)
				incr col($j)
				}
			}
			}}

		## puts "righe per *$may*"
		for { set riga $ri } { $riga<$ri+3 } {incr riga} {

			set in  0
			set out 0

			for { set j $rj } { $j<$rj+3 } {incr j} {

			## puts ""
			for { set i $ri } { $i<$ri+3 } {incr i} {

				set id "$i,$j"
				if { [info exist magic($id)] } {

				if { $row($i) > 0 } {
				## puts -nonewline " row($i)=$row($i)"

				incr in

				if { $i != $riga } {

					incr out
				}
				}

				}

			}}


			## puts " in=$in out=$out"

			if { ($in > 0) && ($out == 0 ) } {

			set rtag "$riga,"
			$w.text tag configure $rtag -background blue
			update idletasks

			puts "$may in line --$riga--"
			incr news

			after 100
			$w.text tag configure $rtag -background {}
			update idletasks

			for { set j $rj } { $j<$rj+3 } {incr j} {

				set ij [lindex [lindex $sudoku $riga] $j]
				puts "($riga,$j) = $ij"

				if { [lsearch -regexp $ij 0] == 0 } {

					set ij "$ij,$may"
					puts "($riga,$j) $ij"

					newij $riga $j $ij 0
				}
			}
			}

		}


		## puts "colonne per *$may*"
		for { set colonna $rj } { $colonna<$rj+3 } {incr colonna} {

			set in  0
			set out 0

			for { set i $ri } { $i<$ri+3 } {incr i} {

			## puts ""
			for { set j $rj } { $j<$rj+3 } {incr j} {

				set id "$i,$j"
				if { [info exist magic($id)] } {

				if { $col($j) > 0 } {
				## puts -nonewline " col($j)=$col($j)"

				incr in

				if { $j != $colonna } {

					incr out
				}
				}

				}

			}}


			## puts " in=$in out=$out"

			if { ($in > 0) && ($out == 0 ) } {

			set ctag "$colonna;"
			$w.text tag configure $ctag -background blue

			puts "$may in coloumn --$colonna--"
			incr news

			after 100
			$w.text tag configure $ctag -background {}
			update idletasks

			for { set i $ri } { $i<$ri+3 } {incr i} {

				set ij [lindex [lindex $sudoku $i] $colonna]
				puts "($i,$colonna) = $ij"

				if { [lsearch -regexp $ij 0] == 0 } {

					set ij "$ij;$may"
					puts "($i,$colonna) $ij"

					newij $i $colonna $ij 0
				}
			}

			}

		}



		}
		return $news
	}


	proc allrangerowcol {} {

		global sudoku magic 

		puts "allrangerowcol:"

		if { [array exist magic] } { unset magic }

		for { set i 0 } { $i<9 } {incr i} {
			for { set j 0 } { $j<9 } {incr j} {

			set ij [lindex [lindex $sudoku $i] $j]

			if { [string index $ij 0] == 0 } {

				newij $i $j 0 0
			}
		}}

		set how 0

		for { set i 0 } { $i<9 } {incr i 3} {
			for { set j 0 } { $j<9 } {incr j 3} {

				if { [tryrange $i $j] > 0 } {

					incr how [whichrowcol $i $j]
				}
			}
		}

		return $how
	}

	proc stop {} {

		global w
		global debug whichproc tryrowcol

		set whichproc 0

		$w.buttons.solve configure -command cont -text " Cont "
	}

	proc cont {} {

		global w
		global debug whichproc nextproc tryrowcol

		set whichproc $nextproc

		trysudoku
	}

	proc trysudoku {} {


		global w 
		global debug whichproc nextproc tryrowcol

		$w.buttons.solve configure -command stop -text " Stop "

		while { $whichproc } {

		switch $whichproc {


			1 {

			# puts ">>>>>>>> 1  allrowcoloums <<<<<<<<<<<<<<"

			set news 0

			while { [incr news [allrowcoloums]] < $news } {

				puts ">>>>>>>>> $news"

				set tryrowcol 1
			}

			puts "now: $news"

			if { [issudoku] == 0 } { 

				puts "END."
				set whichproc 0
				set branchid 0
				$w.buttons.solve configure -state disabled -text " End "

			} else { 

				if { $debug } { 

					set whichproc 0
					set nextproc 2
					puts "nextproc: allranges"
					$w.buttons.solve configure -command cont -text " Cont "
					continue
				}

				set whichproc 2
			}

			}

			2 {

			# puts ">>>>>>>> 2  allranges <<<<<<<<<<<<<<"

			set news 0
			if { [incr news [allranges]] == 0 } { 

				puts "now: $news"

				if { [issudoku] == 0 } { 
						
					puts "END."
					set whichproc 0
					set branchid 0
					$w.buttons.solve configure -state disabled -text " End "

				} else { 

					if { $debug } { 

						set whichproc 0
						set nextproc 3
						puts "nextproc: allrangerowcol"
						$w.buttons.solve configure -command cont -text " Cont "
						continue
					}

					set whichproc 3
				}

			} else {

				puts "now: $news"

				if { $debug } { 

					set whichproc 0
					set nextproc 1
					puts "nextproc: allrowcoloums"
					$w.buttons.solve configure -command cont -text " Cont "
					continue
				}

				set whichproc 1
				set tryrowcol 1
			}
			}

			3 {

			# puts ">>>>>>>> 3  allrangerowcol <<<<<<<<<<<<<<"

			if { $tryrowcol == 0 } { 

				if { $debug } { 

					set whichproc 0
					set nextproc  4
					puts "nextproc: branch"
					$w.buttons.solve configure -command cont -text " Cont "
					continue
				}

				puts "Branching..."

				set whichproc 4
				set tryrowcol 1

				continue
			} 

			set tryrowcol 0

			set news 0
			if { [incr news [allrangerowcol]] == 0 } { 

				puts "now: $news"

				puts "Too Difficult."
				set whichproc 0
				set nextproc 1
				$w.buttons.solve configure -command cont -text " Cont "
				continue

			} else {

				puts "now: $news"

				if { $debug } { 

					set whichproc 0
					set nextproc  1
					puts "nextproc: allrowcoloums"
					$w.buttons.solve configure -command cont -text " Cont "
					continue
				}

				set whichproc 1
			}
			}

			4 {

			# puts ">>>>>>>> 4 branch <<<<<<<<<<<<<<"


			branch


			if { $debug } { 

				set whichproc 0
				set nextproc  1
				puts "nextproc: allrowcoloums"
				$w.buttons.solve configure -command cont -text " Cont "
				continue
			}

			set whichproc 1
			set nextproc  1

			}

		}}
	}

	proc branch {} {

		global w 
		global magic filename tryrowcol
		global BRi BRj BRmay branchid

		global sudoku BRsudoku

		set tryrowcol 1

		switch $branchid {

		0 {



			puts "SAVE FILE $filename"

#			save_sudoku $filename.BR

			set BRsudoku $sudoku
		
			foreach id [array names magic] {

				puts "BR=$id VAL=$magic($id) LEN=[llength $magic($id)]"

				if { [llength $magic($id)] == 2 } {

					set BRi [lindex [split $id ,] 0]
					set BRj [lindex [split $id ,] 1]

					set may [lindex $magic($id) 0]
					set BRmay [lindex $magic($id) 1]


					puts "1st BRANCING i=$BRi j=$BRj may=<$may>"
				
					$w.text tag configure full -background green
					update idletasks

					after 500

					$w.text tag configure full -background {}
					update idletasks

					newij $BRi $BRj $may 1

					break
				}

			}
			
			incr branchid
		}

		1 {
			puts "LOAD FILE $filename.BR"

#			load_sudoku $filename.BR 0;# delete == 0

			set sudoku $BRsudoku

#		file delete $filename.BR

			newtext $filename


			puts "2nd BRANCING i=$BRi j=$BRj may=<$BRmay>"
			after 500

			newij $BRi $BRj $BRmay 1

			incr branchid
		}

		2 {

			puts "Too Difficult."

			set whichproc 0
			set nextproc 4
			$w.buttons.solve configure -command cont -text " Cont "
		}}
		
	}

	proc trysetrowcol {} {

		set try 1

		while { $try > 0 } {

			set rowcol 0

			while { [allrowcoloums] > 0 } { incr rowcol }

			if { [issudoku] > 0 } {

				while { [allranges] > 0 } {

					incr rowcol
				}
			}

			if { [issudoku] > 0 } {

				if { $rowcol == 0 } {

					set try [allrangerowcol]

					if { $try > 0 } {

					set try [allrowcoloums]
					set try [allranges]
					}
				}

			} else {

				set try 0
			}
		} 
	}

	proc tryall {} {

		while { [allranges] > 0 } {

			while { [allrowcoloums] > 0 } {}
		} 
	}

	proc tryseq {} {

		set ranges 1

		while { $ranges > 0 } {

			while { [allrowcoloums] > 0 } {}

			set ranges [allranges]
		} 
	}

	proc print {} {

		global sudoku

		puts "  012 345 678 "
		puts " +---+---+---+"


		for {set i 0} {$i<9} {incr i} {

		if { $i == 3 } { puts " +---+---+---+" }
		if { $i == 6 } { puts " +---+---+---+" }

		puts -nonewline "$i|"
		for {set j 0} {$j<9} {incr j} {

			if { $j == 3 } { puts -nonewline "|" }
			if { $j == 6 } { puts -nonewline "|" }
			set ij [lindex [lindex $sudoku $i] $j]
			puts -nonewline [string index $ij 0]
		}

		puts "|"
		}
		puts " +---+---+---+"
	}

	proc save_sudoku { name } {

		global sudoku
		global w
		global env

#	if { [file exist $name] } {
#
#		puts "file exist <$name>."
#
#		return -1
#	}


		for { set i 0 } { $i<9 } {incr i} {
			for { set j 0 } { $j<9 } {incr j} {

				set ij [lindex [lindex $sudoku $i] $j]

				set where [expr $i+1].[expr $j*2]

				set tags [$w.text tag names $where]

				puts "## ($i,$j) [lindex $tags 1]"
				if { [lindex $tags 1] == "big" } {

				newij $i $j "$ij." 0

				} else {

				newij $i $j [string index $ij 0] 0
				}
			}
		}

#	set file [open $name "w+"]
		if { [catch {open $name "w+"} file] } {

			puts "TMP: $env(TMP)"
			set file [open $env(TMP)\\$name "w+"]
		}
		

		puts $file $sudoku

		close $file

		return 0
	}

	proc load_sudoku { name {delete 1}} {

		global w
		global env
		global sudoku whichproc

#	if { [file exist $name] == 0 } {
#
#		puts "file doesn't exist <$name>."
#
#		return -1
#	}

		set sudoku ""

		if { [catch {open $name "r"} file] } {

			set file [open $env(TMP)\\$name "r"]
		}

		set sudoku [read $file]

		close $file

		if { $delete } {

			if { [file exist $name] } {
			
				file delete $name

			} else {

				file delete $env(TMP)\\$name
			}
		}


		set whichproc 1

		$w.buttons.solve configure -command trysudoku -text "Solve" -state normal

		return 0
	}


	proc buildsudoku { } {

		global sudoku w

		for { set i 0 } { $i<9 } {incr i} {
			for { set j 0 } { $j<9 } {incr j} {

				set ij [lindex [lindex $sudoku $i] $j]
				
				set tags "$i,"
				lappend tags "$j;"
				lappend tags "$i,$j"

				set ri [expr ($i/3)*3]
				set rj [expr ($j/3)*3]
				lappend tags "$ri-$rj"


				if {  [regsub {\.} $ij {} ij] } {
				lappend tags big
				newij $i $j "$ij" 0
				} else {
				lappend tags norm
				}

				puts -nonewline "($i,$j) $ij tags "
				puts "<$tags>"


		    ## zeri/spazi
		    if { [string index $ij 0] == 0 } { set ij " " }

		    $w.text insert end "$ij " $tags

		    $w.text tag lower $ri-$rj

		    if { $j == 8 } {

			$w.text insert end "\n"
		    }

		    # puts "Rtag= $ri-$rj"

		    set Rtag "$ri-$rj"

		    if  { (($ri == 0) || ($ri == 6)) &&
			  (($rj == 0) || ($rj == 6)) ||
			  (($ri == 3) && ($rj == 3)) } {

			$w.text tag configure $Rtag -background #eee
	
		    } else {

			$w.text tag configure $Rtag -background {}

		    }

		    update idletasks
		}
	}

	$w.text tag add full 1.0 9.end
	$w.text tag lower full

	return 0
}

proc sudokuPaste {} {

	global sudoku

	set lll {}

	set CLIP [clipboard get]

	# --- aggiunge spazi tra le cifre ------------
	set CLIP [regsub -all {(\d)(\d)} $CLIP {\1 \2}]
	set CLIP [regsub -all {(\d)(\d)} $CLIP {\1 \2}]

	if { [string length $CLIP] == 161 } {

		set sudoku [list [split $CLIP "\n"]]

	} else {

		set riga 0

		foreach chal [split $CLIP "\n"] {

			set elem [lindex $sudoku 0 $riga]

#			puts "-------$riga-------"
#			puts "ELEM: $elem"
#			puts "CHAL: $chal"

			set RE "\[^ |^."

#--------- SALTA linee senza numeri ------------------------------------

			set lran [lrange $elem 0 [lsearch $elem [lindex $chal 0]]]

			for {set i 1} {$i < [llength $chal]} {incr i} {

#				puts "search: [lsearch $lran [lindex $chal $i]]"

				if { [lsearch $lran [lindex $chal $i]] > 0 } {

#					puts "salta: $riga"

					lappend lll {0 0 0 0 0 0 0 0 0}

					incr riga
					set elem [lindex $sudoku 0 $riga]

					break
				}
			}

#			puts "++-----$riga-----++"
#			puts "ELEM: $elem"
#			puts "CHAL: $chal"

#-------------------------------------------------------------------------
			

			foreach ch [split $chal " "] {

					regsub $ch $elem "${ch}." new

					set elem $new

					append RE "|^$ch"
			}

			append RE "\]"

			regsub -all $RE $elem 0 elem

			lappend lll $elem

			incr riga
		}

		set sudoku $lll
	}

		newtext CLIPBOARD
}

proc newtext { filename } {

	global w

	if { [winfo exist $w.text] } {

		destroy $w.text
	}

	text $w.text -width 25 -height 12 -wrap word 
	pack $w.text -expand yes -fill both

	bind $w.text <<Paste>> {sudokuPaste}
	menu $w.text.menu -tearoff 0
	$w.text.menu add command -label Paste -command {event generate $w.text <<Paste>>}

	bind $w.text <ButtonPress-3> {tk_popup $w.text.menu %X %Y}


##	puts "## <<$filename>>"
	set name [lindex [split $filename /] end]

	regsub {.sdk} $name {} name

	if { $name == "zero" } {

		set name  "Sudoku 1.4"
	}

	wm title . $name

	styles
	buildsudoku
}

proc writeij { i j value } {

	global w
	global filename

	puts "WRITE ($i,$j) $value"

	set where [expr $i+1].[expr $j*2]

	set ijtag "$i,$j"
	$w.text tag configure $ijtag -background red
	update idletasks

	set tags [$w.text tag names $where]

##	set tags [lreplace $tags 0 0 big]

	$w.text delete $where

	$w.text insert $where $value $tags

	after 100
	$w.text tag configure $ijtag -background {}
	update idletasks

	return 0
}

proc sdkfile {operation} {

    global filename

    #   Type names		Extension(s)	Mac File Type(s)
    #
    #---------------------------------------------------------
    set types {
	{"Sudoku files"		{.sdk}		TEXT}
	{"All files"		*}
    }

    if {$operation == "open"} {

	set filename [tk_getOpenFile -filetypes $types -parent .]

	if { $filename != "" } { 

	set filename_list [split $filename .]
	set filename_length [llength $filename_list]

	if { $filename_length == 1 } {

		set sdk "sdk"
		set id ""
		set filename_base $filename

	} elseif { $filename_length == 2 } {

		set sdk [lindex $filename_list end]
		set filename_base [lindex $filename_list 0]

	} else {

	set sdk [lindex $filename_list end]
	set id  [lindex $filename_list [expr $filename_length -2]]
	set filename_base [lrange $filename_list 0 \
		[expr $filename_length -3]]
	}

		if { $sdk != "sdk" } {

			puts "<$filename> is not a Sudoku file"

		} else {

			load_sudoku $filename

			if { [issudoku] != -1 } {

				newtext $filename_base

				set tryrowcol 1
				set branchid  0


			} else {

		puts "<$filename> is not a valid Sudoku file"

			}
		}
	}

    } else {

	puts "FILENAME $filename"

	set filename_list [split $filename .]
	set filename_length [llength $filename_list]

	if { $filename_length == 1 } {

		set sdk "sdk"
		set id ""
		set filename_base $filename

	} elseif { $filename_length == 2 } {

		set sdk [lindex $filename_list end]
		set id 1
		set filename_base [lindex $filename_list 0]

	} else {

	set sdk [lindex $filename_list end]
	set id  [lindex $filename_list [expr $filename_length -2]]
	set filename_base [lrange $filename_list 0 \
		[expr $filename_length -3]]
	}

	set id 1
	while { [file exist $filename_base.$id.sdk] } {

		incr id
	}

	if { [issudoku] == 0 } { 

		set id end
	}

	set newfile $filename_base.$id.sdk

	puts "SAVING $newfile"
	set filename [tk_getSaveFile -filetypes $types -parent . \
	    -initialfile $newfile -defaultextension .sdk]

	if { $filename != "" } {

		save_sudoku $filename
		set filename $newfile
	}
    }
}


#
# MAIN
#

array set magic ""

set branchid 0

set whichproc 1
set nextproc  0
set tryrowcol 1

set debug     0

#puts "0 $argv0"
#puts "1 $argv"

set filename $filename6
set sudoku $sudoku6

newtext $filename

puts "ready."
