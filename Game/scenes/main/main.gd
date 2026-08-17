extends Node
## Main
##
## Ponto de entrada do jogo (run/main_scene). Sua única responsabilidade é
## encaminhar a execução para a Cidade — o hub principal do jogo —,
## mantendo main.tscn livre de qualquer lógica de inicialização.
##
## O Bootstrap (scenes/bootstrap/bootstrap.tscn, com todas as
## validações automáticas do projeto) continua existindo — só não é
## mais o destino padrão. Rode-o diretamente (abra a cena e aperte F6)
## quando precisar validar o projeto inteiro; "rodar o projeto"
## (F5/Play) agora abre o jogo de verdade.


func _ready() -> void:
	# call_deferred evita o erro "Parent node is busy adding/removing children":
	# a troca de cena só ocorre depois que a árvore termina a inicialização atual.
	get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")
