function button_on_click(){
	let typelist = [];
	if(document.getElementById("chk_linear").checked){typelist.push('DimensionLinear');}
	if(document.getElementById("chk_radial").checked){typelist.push('DimensionRadial');}
	if(document.getElementById("chk_text").checked){typelist.push('Text');}
	let orientlist = [];
	if(document.getElementById("chk_axis_x").checked){orientlist.push('x');}
	if(document.getElementById("chk_axis_y").checked){orientlist.push('y');}
	if(document.getElementById("chk_axis_z").checked){orientlist.push('z');}
	if(document.getElementById("chk_axis_yz").checked){orientlist.push('yz');}
	if(document.getElementById("chk_axis_xz").checked){orientlist.push('xz');}
	if(document.getElementById("chk_axis_xy").checked){orientlist.push('xy');}
	if(document.getElementById("chk_axis_xyz").checked){orientlist.push('xyz');}
	if(document.getElementById("chk_axis_0").checked){orientlist.push('0');}
	let e1 = parseInt(document.getElementById('edit_min_length').value);
	let e2 = parseInt(document.getElementById('edit_max_length').value);
	let u1 = document.getElementById("select_min_unit").value;
	let u2 = document.getElementById("select_max_unit").value;
	let listview = document.getElementById("result_list");
	listview.innerHTML = "";
	result_list = sketchup.do_filter(typelist, orientlist, e1, e2, u1, u2);
}
function appendItem(typename, caption, pid){
	let listview = document.getElementById("result_list");
	let item = document.createElement('div');
	item.className = "result_item";
	item.setAttribute("pid",pid)
	let item_type = document.createElement('div');
	let item_caps = document.createElement('div');
	item_type.innerHTML = typename;
	item_caps.innerHTML = caption;
	item_type.className = "item_type";
	item_caps.className = "item_caption";
	item.appendChild(item_type);
	item.appendChild(item_caps);
	item.addEventListener('click',Function("item_on_click(this);"));
	listview.appendChild(item);
}
function item_on_click(sender){
	let pid = sender.getAttribute("pid");
	sketchup.do_zoom(pid);
}