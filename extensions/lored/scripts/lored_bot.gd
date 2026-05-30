extends LORED


static var bot1: Node


func _can_start_job(job: Job, _input: Dictionary[StringName, Big] = {}) -> bool:
	if key == &"bot":
		if bot1 == null:
			bot1 = Stage.fetch(&"curator1").node.bots.get_child(0)
		
		if job.key == &"deploy" and bot1.count.is_full():
			return false
		elif job.key == &"refactor" and not bot1.count.is_full():
			return false
	
	return super(job, _input)


func get_job_output(job: Job, base_output: Big) -> Dictionary[StringName, Big]:
	var result: Dictionary[StringName, Big]
	
	if key == &"bot":
		if job.key == &"deploy":
			result[&"bot"] = Big.new(bot1.count.get_deficit())
			return result
	
	result = super(job, base_output)
	return result
