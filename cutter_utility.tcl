#!/usr/bin/wish
#
# Program to send (HPGL) files to Smurf cutter (HW330)
# via USB to serial interface
# Run as root or set ttyUSB permissions correctly
#
# One argument to script: the ttyUSB device the cutter is plugged in to.
#

set device   [lindex $argv 0]

puts "Opening $device"
set f [open $device r+]

fconfigure $f -blocking 0
fconfigure $f -mode 38400,n,8,1
fconfigure $f -handshake rtscts -buffering none -translation binary
fileevent $f readable "read_data $f"


####################################################################################################
#
# Sending @ exits DMPL mode and USB comms
#
# Any buffered file will be cut to the end of the file
#

proc exit_comms {} {
    global f
    puts $f "@"
    
}

####################################################################################################
#
# Sends a file to the Smurf
# Requires upload menu to be selected before executing 
#

proc send_cut_file_dialog {} {
    global f
    
    set types {

	    {{HP-GL Files} {.hpgl}}
	    {{PLT Files} {.plt .PLT}}

    }
    
    set filename [tk_getOpenFile -initialdir ../z80_c -filetypes $types]

    if { $filename != "" } {
	send_cut_file $filename $f
    }
}

####################################################################################################
#
# Open a window for terminal interaction
#

proc open_terminal_window {w} {
    frame $w
    eval {text $w.text \
	      -xscrollcommand [list $w.xscroll set] \
	      -yscrollcommand [list $w.yscroll set]} -width 135 -height 50
    scrollbar $w.xscroll -orient horizontal \
	-command [list $w.text xview]
    scrollbar $w.yscroll -orient vertical \
	-command [list $w.text yview]
    grid $w.text $w.yscroll -sticky news
    grid $w.xscroll -sticky news
    grid rowconfigure    $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1
    
    bind $w.text <Any-Key> "write_data %A"
    
    #Main menu
    menu $w.menu -tearoff 0
    
    $w.menu add cascade -label "File"  -menu $w.menu.file -underline 0
    $w.menu add cascade -label "Cutter Control" -menu $w.menu.cutterctrl -underline 0
    $w.menu add cascade -label "About" -menu $w.menu.about -underline 0
    
    menu $w.menu.file -tearoff 0
    menu $w.menu.cutterctrl -tearoff 0
    menu $w.menu.about -tearoff 0
    
    set m $w.menu.file
    $m add command -label "Send HPGL File" -command {send_cut_file_dialog}
    $m add command -label "Exit" -command exit
    
    set m $w.menu.cutterctrl
    $m add command -label "Exit comms" -command {exit_comms}
    
    set m $w.menu.about
    $m add command -label "Smurf HW330 Cutter Utility"
    $m add command -label "Version 1.0"
    
    . configure -menu $w.menu
    
    return $w.text
}

proc send_cut_file {filename f} {
    
    set start_clock [clock seconds]
    
    # Read the hex file
    
    set g [open $filename]
    set txt [read $g]
    close $g
    
    # Flush
    puts "Flushing..."
    set done 0
    while { !$done } {
	set tx [read $f]
	if { [string length $tx] == 0 } {
	    set done 1
	} else {
	    puts $tx
	}
    }
    
    
    puts "Sending $filename"
    
    set i 0
    
    foreach line [split $txt ";"] {
	if { [string length $line] == 0 } {
	    break
	}
	
	puts $f "$line;"
	flush $f
	
	incr i 1
	if { [expr ($i % 100)==0] } {
	    puts "Sent $i lines..."
	}
    }

    # End transfer
    puts $f "@"
    
    set end_clock [clock seconds]
    
    set elapsed [expr $end_clock - $start_clock]
    puts "Elapsed time:$elapsed"
}

proc write_data {txt} {
    global f
    puts "W:$txt"
    puts -nonewline $f $txt
    flush $f
}

open_terminal_window .t
pack .t -side top -fill both -expand true

# Drop into event loop...
write_data "\n"


