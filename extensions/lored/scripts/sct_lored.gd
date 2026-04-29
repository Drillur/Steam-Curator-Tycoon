extends Object


static var bot1: Node


func _can_start_job(chain: ModLoaderHookChain, job: Job,
		_input: Dictionary[StringName, Big] = {}) -> bool:
	
	if chain.reference_object.key == &"bot":
		if bot1 == null:
			bot1 = Stage.fetch(&"curator1").node.bots.get_child(0)
		
		if job.key == &"deploy" and bot1.count.is_full():
			return false
		elif job.key == &"refactor" and not bot1.count.is_full():
			return false
	
	return chain.execute_next([job, _input])


func get_job_output(chain: ModLoaderHookChain, job: Job,
		base_output: Big) -> Dictionary[StringName, Big]:
	
	var result: Dictionary[StringName, Big]
	var lored: LORED = chain.reference_object
	
	if chain.reference_object.key == &"bot":
		if job.key == &"deploy":
			result[&"bot"] = Big.new(lored.current_crit_multiplier)
			return result
	
	result = chain.execute_next([job, base_output])
	return result
