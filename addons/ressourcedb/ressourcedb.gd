@tool
extends EditorPlugin

var db_path := "res://addons/ressourcedb/demo/"
var filesystem: EditorFileSystem
var db := {}
var db_script := "" 
var file_popup := EditorFileDialog.new()

func select_path(path: String):
	db_path = path
	var path_save_file := FileAccess.open("res://addons/ressourcedb/path.txt", FileAccess.WRITE)
	path_save_file.store_string(db_path)
	path_save_file.close()
	filesystem.scan()

func _enter_tree():
	file_popup.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	file_popup.dir_selected.connect(select_path)
	filesystem = EditorInterface.get_resource_filesystem()
	filesystem.filesystem_changed.connect(_on_filesystem_changed)
	var path_save_file := FileAccess.open("res://addons/ressourcedb/path.txt", FileAccess.READ)
	db_path = path_save_file.get_as_text()
	path_save_file.close()
	
	EditorInterface.get_editor_main_screen().add_child(file_popup)
	add_autoload_singleton("DB", "res://addons/ressourcedb/database.gd")
	add_tool_menu_item("Set DB Path", file_popup.popup_file_dialog)

func _on_filesystem_changed():
	var dir = DirAccess.open(db_path)
	if dir == null: return
	db = {}
	gen_db(dir)
	db_script = "extends Node \n\n"	
	
	for key in db.keys() as Array[String]:
		db_script += "const " + key.to_upper() + " := { \n" 
		for inner_key in db[key].keys() as Array[String]:
			db_script += "	&\"" + inner_key + "\": "+ db[key][inner_key] +", \n" 
		db_script += "}\n"
	
	if FileAccess.file_exists("res://addons/ressourcedb/database.gd"):
		var file := FileAccess.open("res://addons/ressourcedb/database.gd", FileAccess.READ)
		if file.get_as_text() == db_script: return 
	var file = FileAccess.open("res://addons/ressourcedb/database.gd", FileAccess.WRITE)
	file.store_string(db_script)
	file.close()
	filesystem.scan()

func gen_db(source: DirAccess):
	var dir = DirAccess.open(source.get_current_dir())
	var dir_name = source.get_current_dir().get_file()
	db[dir_name] = {}
	for file in dir.get_files():
		if not file.ends_with(".tres") && not file.ends_with(".res") && not file.ends_with(".tscn"): continue
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
