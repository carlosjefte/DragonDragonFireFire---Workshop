class_name PlayerAIController
extends AIController2D

@onready var player: Player = _get_player_safely()

var ai_input_direction: float = 0.0
var ai_input_jump: bool = false
var ai_input_fire: bool = false
var ai_input_up: bool = false
var ai_input_down: bool = false

# Controle de pontuação e tempo para o cálculo de recompensa
var last_score: int = 0
var level_time_elapsed: float = 0.0

const MAX_ENEMIES_OBS: int = 3
const MAX_PROJECTILES_OBS: int = 3
const MAX_ITEMS_OBS: int = 2
const MAX_PLATFORMS_OBS: int = 3

func _get_player_safely() -> Player:
	# DICA: Implemente a busca segura pelo Player na árvore de cena.
	# 1. Obtenha a cena atual usando `get_tree().current_scene`.
	# 2. Se não existir, retorne `null`.
	# 3. Percorra a árvore (ou utilize uma função recursiva) para encontrar o nó do tipo Player.
	pass

func _find_all_players(node: Node) -> Array:
	# DICA: Crie uma função recursiva que percorre os filhos de um nó.
	# Se o nó atual for do tipo `Player`, adicione-o a um array de resultados.
	# Retorne o array com todos os players encontrados.
	pass

func get_action_space() -> Dictionary:
	# DICA: Defina o espaço de ações que o modelo de IA pode tomar.
	# Retorne um Dicionário contendo:
	# - "move_action": contínuo (tamanho 1)
	# - "jump_action", "fire_action", "up_action", "down_action": discretos (tamanho 1)
	return {}

func set_action(action) -> void:
	# DICA: Aplique as ações escolhidas pela IA no Player.
	# 1. Certifique-se de que o player é válido.
	# 2. Extraia os valores do dicionário `action` passado pelo algoritmo de RL.
	# 3. Atribua os valores correspondentes às variáveis `ai_input_*` e aos atributos do player.
	pass

func get_obs() -> Dictionary:
	# DICA: Monte o vetor de observações (estado do jogo) que será enviado para a IA.
	# 1. Adicione a velocidade do player (velocity.x, velocity.y) e se ele está no chão (is_on_floor).
	# 2. Encontre e ordene os inimigos, projéteis, itens e plataformas mais próximos.
	# 3. Calcule as posições relativas (posição do objeto - posição do player) e adicione ao array `obs`.
	# 4. Garanta que o array tenha o tamanho fixo esperado (ex: preenchendo com 0.0 até o tamanho 31).
	var obs: Array = []
	
	# [Seu código de observações aqui]
	
	return { "obs": obs }

func get_obs_space() -> Dictionary:
	# DICA: Retorne o dicionário que descreve o formato e o tamanho da observação (ex: tamanho 31, tipo "box").
	return {}

func get_reward() -> float:
	# DICA: Calcule a recompensa (reward) que treina a IA a atingir o objetivo.
	# Considere:
	# - Punição progressiva por tempo para incentivar a agilidade.
	# - Recompensa positiva quando o score aumentar (pontos ganhos).
	# - Punição pesada se o player morrer (`player.State.DEAD`), e um pequeno bônus por sobrevivência.
	var reward = 0.0
	
	# [Seu código de cálculo de recompensa aqui]
	
	return reward

func reset() -> void:
	# DICA: Resete as variáveis de controle de episódio (ex: zerar o tempo decorrido e atualizar o last_score).
	pass

func _find_nodes_of_class(node: Node, class_name_str: String) -> Array:
	# DICA: Função utilitária para buscar nós por nome de classe ou script de forma recursiva.
	pass

func _find_nodes_in_group_or_name(node: Node, keyword: String) -> Array:
	# DICA: Função utilitária para buscar nós que pertencem a um grupo específico ou contêm uma palavra-chave no nome.
	pass

func _find_platforms(node: Node) -> Array:
	# DICA: Função utilitária para encontrar plataformas ou tilemaps na cena atual.
	pass

func get_info() -> Dictionary:
	# DICA: Retorne informações extras úteis para debug (como o estágio atual do jogo).
