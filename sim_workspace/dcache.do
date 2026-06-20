cd "D:/HCMUS/THESIS"
set env(HPDCACHE_DIR) "D:/HCMUS/THESIS/cv-hpdcache-master"
set project_name "core"

if {[file exists ${project_name}.mpf]} {
    file delete -force ${project_name}.mpf
}
if {[file exists work]} {
    vdel -lib work -all
}

project new . $project_name work
project open $project_name

set flist_path "$env(HPDCACHE_DIR)/rtl/hpdcache.Flist"
set fp [open $flist_path r]
set file_data [read $fp]
close $fp

set lines [split $file_data "\n"]
foreach line $lines {
    set line [string trim $line]
    if {$line eq "" || [string match "//*" $line] || [string match "+incdir+*" $line]} {
        continue
    }
    set full_path [subst [string map {\${HPDCACHE_DIR} "D:/HCMUS/THESIS/cv-hpdcache-master"} $line]]
    if {[file exists $full_path]} {
        project addfile $full_path systemverilog
    }
}

project compilearguments -incdir "$env(HPDCACHE_DIR)/rtl/include"
project calculateorder
project compileall