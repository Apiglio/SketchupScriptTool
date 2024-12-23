function append_dictionary(dict_name){
	let content = document.getElementById("content");
	let dictdiv = document.createElement("div");
	dictdiv.className = "dictionary";
	dictdiv.id = dict_name;
	dictdiv.innerHTML = `<h2>${dict_name}</h2>`
	content.appendChild(dictdiv);
}
function append_attribute(dict_name, attr_name){
	let dictdiv = document.getElementById(dict_name);
	let attrdiv = document.createElement("div");
	attrdiv.className = "attribute";
	attrdiv.id = dict_name+"."+attr_name;
	attrdiv.setAttribute("dict",dict_name);
	attrdiv.setAttribute("attr",attr_name);
	attrdiv.innerHTML = `<div class="key">${attr_name}</div><textarea class="value"></textarea>`
	dictdiv.appendChild(attrdiv);
}
function update_data(jsobj){
	let list_attrdiv = document.querySelectorAll('div.attribute');
	for(attrdiv of list_attrdiv){
		dict_name = attrdiv.getAttribute("dict");
		attr_name = attrdiv.getAttribute("attr");
		text_area = attrdiv.querySelector('textarea');
		if(dict_name in jsobj["attr"] && attr_name in jsobj["attr"][dict_name]){
			text_area.value = jsobj["attr"][dict_name][attr_name];
			text_area.setAttribute("status","");
		}
	}
}
function export_data(){
	result = {};
	let list_attrdiv = document.querySelectorAll('div.attribute');
	for(attrdiv of list_attrdiv){
		dict_name = attrdiv.getAttribute("dict");
		attr_name = attrdiv.getAttribute("attr");
		text_area = attrdiv.querySelector('textarea');
		if(!(dict_name in result)){result[dict_name]={};}
		result[dict_name][attr_name]=text_area.value;
	}
	return {"attr":result};
}
function reset_items(dict_and_attr){
	document.getElementById('content').innerHTML='';
	for(dict_name in dict_and_attr){
		append_dictionary(dict_name);
		for(attr_name of dict_and_attr[dict_name]){
			append_attribute(dict_name, attr_name);
		}
	}
}
function clear_items(){
	let list_attrdiv = document.querySelectorAll('div.attribute');
	for(attrdiv of list_attrdiv){
		text_area = attrdiv.querySelector('textarea')
		text_area.value = "";
		text_area.setAttribute("status","lock");
	}
}
function reset_on_click(){
	sketchup.read_entity();
}
function apply_on_click(){
	sketchup.write_entity(export_data());
}