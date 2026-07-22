class_name V1YamlSubset
extends RefCounted

var error_message := ""

func parse_file(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		error_message = "cannot open %s" % path
		return null
	return parse(file.get_as_text())

func parse(text: String) -> Variant:
	error_message = ""
	var lines: Array = []
	var raw_lines := text.replace("\r\n", "\n").split("\n")
	for index in raw_lines.size():
		var raw: String = raw_lines[index]
		if raw.strip_edges().is_empty():
			continue
		if raw.contains("\t"):
			return _fail(index + 1, "tabs are unsupported")
		var indent := 0
		while indent < raw.length() and raw[indent] == " ":
			indent += 1
		if indent % 2 != 0:
			return _fail(index + 1, "indentation must use two-space steps")
		var content := raw.substr(indent)
		if content.begins_with("#") or content.contains(" #"):
			return _fail(index + 1, "comments are unsupported")
		lines.append({"line": index + 1, "indent": indent, "text": content})
	if lines.is_empty():
		return _fail(1, "document is empty")
	var cursor := [0]
	var result: Variant = _parse_block(lines, cursor, lines[0].indent)
	if not error_message.is_empty():
		return null
	if cursor[0] != lines.size():
		return _fail(lines[cursor[0]].line, "unexpected content")
	return result

func _parse_block(lines: Array, cursor: Array, indent: int) -> Variant:
	if lines[cursor[0]].indent != indent:
		return _fail(lines[cursor[0]].line, "unexpected indentation")
	if String(lines[cursor[0]].text).begins_with("-"):
		return _parse_sequence(lines, cursor, indent)
	return _parse_mapping(lines, cursor, indent)

func _parse_mapping(lines: Array, cursor: Array, indent: int) -> Variant:
	var result := {}
	while cursor[0] < lines.size() and lines[cursor[0]].indent == indent and not String(lines[cursor[0]].text).begins_with("-"):
		var entry: Dictionary = lines[cursor[0]]
		var content: String = entry.text
		var colon := content.find(":")
		if colon <= 0:
			return _fail(entry.line, "mapping entry requires a non-empty key")
		var key := content.substr(0, colon)
		if key.strip_edges() != key or not _valid_key(key):
			return _fail(entry.line, "unsupported or ambiguous mapping key")
		if result.has(key):
			return _fail(entry.line, "duplicate key '%s'" % key)
		var rest := content.substr(colon + 1)
		if rest.begins_with(" "):
			rest = rest.substr(1)
		elif not rest.is_empty():
			return _fail(entry.line, "a colon must be followed by one space")
		cursor[0] += 1
		if rest.is_empty():
			if cursor[0] >= lines.size() or lines[cursor[0]].indent < indent:
				return _fail(entry.line, "missing nested value for '%s'" % key)
			if lines[cursor[0]].indent == indent and String(lines[cursor[0]].text).begins_with("-"):
				result[key] = _parse_sequence(lines, cursor, indent)
			elif lines[cursor[0]].indent == indent + 2:
				result[key] = _parse_block(lines, cursor, indent + 2)
			else:
				return _fail(lines[cursor[0]].line, "nested indentation must increase by two")
		else:
			result[key] = _parse_scalar(rest, entry.line)
			if not error_message.is_empty(): return null
	return result

func _parse_sequence(lines: Array, cursor: Array, indent: int) -> Variant:
	var result := []
	while cursor[0] < lines.size() and lines[cursor[0]].indent == indent and String(lines[cursor[0]].text).begins_with("-"):
		var entry: Dictionary = lines[cursor[0]]
		var content: String = entry.text
		var rest := content.substr(1)
		if rest.begins_with(" "): rest = rest.substr(1)
		elif not rest.is_empty(): return _fail(entry.line, "dash must be followed by one space")
		cursor[0] += 1
		if rest.is_empty():
			if cursor[0] >= lines.size() or lines[cursor[0]].indent != indent + 2:
				return _fail(entry.line, "sequence item has no value")
			result.append(_parse_block(lines, cursor, indent + 2))
		elif rest.contains(":"):
			var colon := rest.find(":")
			var key := rest.substr(0, colon)
			if not _valid_key(key): return _fail(entry.line, "unsupported sequence mapping key")
			var item := {}
			var value_text := rest.substr(colon + 1)
			if value_text.begins_with(" "): value_text = value_text.substr(1)
			elif not value_text.is_empty(): return _fail(entry.line, "a colon must be followed by one space")
			if value_text.is_empty(): return _fail(entry.line, "inline sequence mapping value is required")
			item[key] = _parse_scalar(value_text, entry.line)
			if cursor[0] < lines.size() and lines[cursor[0]].indent == indent + 2:
				var tail = _parse_mapping(lines, cursor, indent + 2)
				for tail_key in tail: item[tail_key] = tail[tail_key]
			result.append(item)
		else:
			result.append(_parse_scalar(rest, entry.line))
		if not error_message.is_empty(): return null
	return result

func _parse_scalar(value: String, line: int) -> Variant:
	if value == "[]": return []
	if value == "{}": return {}
	if value == "true": return true
	if value == "false": return false
	if value == "null" or value == "~": return _fail(line, "null scalars are unsupported")
	if value.begins_with("[") or value.begins_with("{") or value.begins_with("&") or value.begins_with("*") or value.begins_with("!") or value.begins_with("|") or value.begins_with(">"):
		return _fail(line, "unsupported YAML scalar syntax")
	if value.begins_with("\"") or value.begins_with("'"):
		return _fail(line, "quoted scalars are unsupported")
	if value.is_valid_int():
		if (value.begins_with("0") and value.length() > 1) or value.begins_with("-0"):
			return _fail(line, "ambiguous leading-zero integer")
		return value.to_int()
	if value.is_valid_float() and (value.contains(".") or value.contains("e") or value.contains("E")):
		return value.to_float()
	if value.strip_edges() != value or value.contains(": ") or value.ends_with(":"):
		return _fail(line, "ambiguous plain scalar")
	return value

func _valid_key(key: String) -> bool:
	if key.is_empty(): return false
	for c in key:
		if not (c >= "a" and c <= "z") and not (c >= "A" and c <= "Z") and not (c >= "0" and c <= "9") and c != "_" and c != "-": return false
	return true

func _fail(line: int, message: String) -> Variant:
	error_message = "line %d: %s" % [line, message]
	return null
