class_name ArmyCardSlot
extends Control
## ArmyCardSlot
##
## Control genérico e sem conhecimento de domínio nenhum — só liga os
## dois mecanismos NATIVOS do Godot que o Editor de Exército precisa
## (tooltip customizado via _make_custom_tooltip() e Drag-and-Drop via
## _get_drag_data()/_can_drop_data()/_drop_data()) a Callables fornecidas
## por quem o cria. Toda a lógica de Carta/Comandante/Exército continua
## em army_editor_panel.gd; esta classe nunca decide nada sozinha.
##
## GAP verificado antes de criar este arquivo: não existe nenhum
## componente de Drag-and-Drop reutilizável em nenhum outro lugar do
## projeto (nenhuma outra tela usa _get_drag_data/_can_drop_data/
## _drop_data) — esta é a primeira vez que a interação é necessária.

## Retorna o Control a mostrar como tooltip nativo do Godot, ou deixa
## sem efeito (Callable inválida = sem tooltip).
var tooltip_builder: Callable = Callable()

## Retorna o payload de drag (qualquer Variant, tipicamente um
## Dictionary), ou null se este slot não deve iniciar um drag agora
## (ex: posição vazia da Formação).
var drag_data_builder: Callable = Callable()

## Retorna o Control usado como prévia visual seguindo o cursor durante
## o drag. Opcional — sem Callable válida, usa a prévia padrão do Godot.
var drag_preview_builder: Callable = Callable()

## Recebe o payload do drag em andamento, retorna se este slot aceita
## soltá-lo agora.
var can_drop_checker: Callable = Callable()

## Recebe o payload solto sobre este slot — aplica o efeito real
## (colocar/trocar Carta).
var drop_handler: Callable = Callable()

## Preenchido automaticamente por set_tooltip_builder() — precisa de um
## tooltip_text não-vazio para o Godot sequer considerar chamar
## _make_custom_tooltip() (comportamento nativo do Control).
const _TOOLTIP_MARKER: String = " "


func set_tooltip_builder(builder: Callable) -> void:
	tooltip_builder = builder
	tooltip_text = _TOOLTIP_MARKER if builder.is_valid() else ""


func _make_custom_tooltip(_for_text: String) -> Object:
	if not tooltip_builder.is_valid():
		return null
	return tooltip_builder.call()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not drag_data_builder.is_valid():
		return null
	var data: Variant = drag_data_builder.call()
	if data == null:
		return null
	if drag_preview_builder.is_valid():
		var preview: Control = drag_preview_builder.call()
		if preview != null:
			set_drag_preview(preview)
	return data


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not can_drop_checker.is_valid():
		return false
	return can_drop_checker.call(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if drop_handler.is_valid():
		drop_handler.call(data)
