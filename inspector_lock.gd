@tool
extends EditorPlugin

var lock_button: Button
var locked_object: Object = null
var is_locked: bool = false

var guard: bool = false

func _enter_tree():
	# criar o botaozinho de travar
	lock_button = Button.new()
	lock_button.flat = true
	lock_button.toggle_mode = true
	lock_button.tooltip_text = "Lock Inspector"
	lock_button.focus_mode = Control.FOCUS_NONE
	
	# faz o setup la do botao
	call_deferred("_update_button_icon")
	
	# conecta os signals
	lock_button.toggled.connect(_on_button_toggled)
	
	var selection = get_editor_interface().get_selection()
	selection.selection_changed.connect(_on_selection_changed)
	
	var inspector = get_editor_interface().get_inspector()
	inspector.edited_object_changed.connect(_on_inspector_changed)
	

	var inspector_parent = inspector.get_parent()
	var target_container: HBoxContainer = null
	
	for child in inspector_parent.get_children():
		if child is HBoxContainer:
			if child.visible and child.get_child_count() > 0:
				target_container = child
				break
	
	if target_container:
		target_container.add_child(lock_button)
	else:
		inspector_parent.add_child(lock_button)
		inspector_parent.move_child(lock_button, 0)
		lock_button.size_flags_horizontal = Control.SIZE_SHRINK_END

func _exit_tree():
	if lock_button:
		lock_button.get_parent().remove_child(lock_button)
		lock_button.queue_free()

func _update_button_icon():
	if not lock_button:
		return
	
	var base = get_editor_interface().get_base_control()
	if is_locked:
		lock_button.icon = base.get_theme_icon("Lock", "EditorIcons")
		lock_button.modulate = Color(1.0, 0.735, 0.682, 1.0)
	else:
		lock_button.icon = base.get_theme_icon("Unlock", "EditorIcons")
		lock_button.modulate = Color(1, 1, 1)

func _on_button_toggled(toggled_on: bool):
	is_locked = toggled_on
	_update_button_icon()
	
	var inspector = get_editor_interface().get_inspector()
	
	if is_locked:
		locked_object = inspector.get_edited_object()
		if locked_object == null:
			lock_button.set_pressed_no_signal(false)
			is_locked = false
	else:
		locked_object = null
		_on_selection_changed()

func _on_selection_changed():
	if not is_locked or guard:
		return

	if locked_object and is_instance_valid(locked_object):
		_enforce_lock()
		
		call_deferred("_enforce_lock")

func _on_inspector_changed():
	if not is_locked or guard:
		return
	
	var inspector = get_editor_interface().get_inspector()
	if inspector.get_edited_object() != locked_object:
		if locked_object and is_instance_valid(locked_object):
			_enforce_lock()
			call_deferred("_enforce_lock")
		else:
			lock_button.button_pressed = false

func _enforce_lock():
	if is_locked and locked_object and is_instance_valid(locked_object):
		guard = true
		var inspector = get_editor_interface().get_inspector()
		inspector.edit(locked_object)
		guard = false
