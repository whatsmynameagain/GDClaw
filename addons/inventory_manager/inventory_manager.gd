@tool
extends EditorPlugin

#don't edit and save any scripts from the plugin without disabling it first

var dock = preload("res://addons/inventory_manager/inventory.tscn").instantiate()
var editor_selection = get_editor_interface().get_selection()
var selection : Array


func _enter_tree():
	dock.connect("inventory_changed", Callable(self, "_on_inventory_changed"))
	editor_selection.connect("selection_changed", Callable(self, "_on_selection_changed"))
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)


func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()


func _on_selection_changed():
	selection = editor_selection.get_selected_nodes() 
	if not (selection.is_empty() or len(selection) > 1):
		var script = selection[0].get_script()
		if script and !script.is_tool():
			return
		if !selection[0].has_method("_is_class"):
			return
		if selection[0]._is_class("Crate") or selection[0]._is_class("Enemy"):
			dock.toggle(true)
			dock.set_selection_contents(selection[0].contents) #duplicate made in the method
		else:
			dock.clear()
			dock.toggle(false)


func _on_inventory_changed(inv) -> void:
	selection[0].contents = inv.duplicate(true)
	dock.set_selection_contents(selection[0].contents.duplicate(true)) 
	#update the selection in the inventory
