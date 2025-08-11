@tool
extends EditorPlugin

const DATA_PATH = "res://data"
var filesystem: EditorFileSystem
var db = {}
var db_script := ""


func _enter_tree():
	filesystem = EditorInterface.get_resource_filesystem()
	filesystem.filesystem_changed.connect(_on_filesystem_changed)
	add_autoload_singleton("DB", "res://addons/autogendb/database.gd")

func _on_filesystem_changed():
	var dir = DirAccess.open(DATA_PATH)
	db = {}
	gen_db(dir)
	db_script = "extends Node \n\n"	
	
	for key in db.keys() as Array[String]:
		db_script += "const " + key.to_upper() + " := { \n" 
		for inner_key in db[key].keys() as Array[String]:
			db_script += "	&\"" + inner_key + "\": "+ db[key][inner_key] +", \n" 
		db_script += "}\n"
	
	if FileAccess.file_exists("res://addons/autogendb/database.gd"):
		var file = FileAccess.open("res://addons/autogendb/database.gd", FileAccess.READ)
		if file.get_as_text() == db_script: return 
	var file = FileAccess.open("res://addons/autogendb/database.gd", FileAccess.WRITE)
	file.store_string(db_script)

func gen_db(source: DirAccess):
	var dir = DirAccess.open(source.get_current_dir())
	var dir_name = source.get_current_dir().get_file()
	db[dir_name] = {}
	for file in dir.get_files():
		if not file.ends_with(".tres") && not file.ends_with(".res") && not file.ends_with(".tscn"): return
		var temp = file
		if file.ends_with(".tres"): temp = temp.substr(0, temp.length() - 5)
		if file.ends_with(".res"): temp = temp.substr(0, temp.length() - 4)
		if file.ends_with(".tscn"): temp = temp.substr(0, temp.length() - 5)
		db[dir_name][temp] = "preload(\""+source.get_current_dir()+"/"+file+"\")"
	
	for sub_dir in dir.get_directories():
		gen_db(DirAccess.open(source.get_current_dir()+"/"+sub_dir))
	pass

func _exit_tree():
	filesystem.filesystem_changed.disconnect(_on_filesystem_changed)
	remove_autoload_singleton("DB")
