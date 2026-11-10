extends RefCounted
# T-030: ScoreSink receives every finished day (as an input-log record) and the end of a run. This base
# class is the interface; local_score_sink.gd writes the local profile. An online sink would send the
# same record to a server, which re-simulates and returns the verified score.

# Returns {"toasts": [String], "score": int, ...}.
func submit_day(_record: Dictionary) -> Dictionary:
	return {"toasts": []}

func finish_run(_status: Dictionary) -> Dictionary:
	return {"toasts": []}
