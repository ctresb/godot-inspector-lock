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
	lock_button.tooltip_text = "Pin Inspector"
	lock_button.focus_mode = Control.FOCUS_NONE

	# faz o setup la do botao
	call_deferred("_update_button_icon")

	# conecta os signals
	lock_button.toggled.connect(_on_button_toggled)

	var selection = EditorInterface.get_selection()
	selection.selection_changed.connect(_on_selection_changed)

	var inspector = EditorInterface.get_inspector()
	inspector.edited_object_changed.connect(_on_inspector_changed)

	# The parent "Inspector" is an InspectorDock instance
	var dock = inspector.find_parent("Inspector")
	var vbox = dock.get_child(0) as VBoxContainer
	var hbox = vbox.get_child(0) as HBoxContainer
	hbox.add_child(lock_button)


func _exit_tree():
	if lock_button:
		lock_button.get_parent().remove_child(lock_button)
		lock_button.queue_free()

func _update_button_icon():
	if not lock_button:
		return

	var base = EditorInterface.get_base_control()
	if is_locked:
		lock_button.icon = base.get_theme_icon("Pin", "EditorIcons")
		lock_button.modulate = base.get_theme_color("icon_pressed_color", "Button")
	else:
		lock_button.icon = base.get_theme_icon("Pin", "EditorIcons")
		lock_button.modulate = base.get_theme_color("icon_normal_color", "Button")

func _on_button_toggled(toggled_on: bool):
	is_locked = toggled_on
	_update_button_icon()

	var inspector = EditorInterface.get_inspector()

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

	var inspector = EditorInterface.get_inspector()
	if inspector.get_edited_object() != locked_object:
		if locked_object and is_instance_valid(locked_object):
			_enforce_lock()
			call_deferred("_enforce_lock")
		else:
			lock_button.button_pressed = false

func _enforce_lock():
	if is_locked and locked_object and is_instance_valid(locked_object):
		guard = true
		var inspector = EditorInterface.get_inspector()
		inspector.edit(locked_object)
		guard = false
