extends MeshInstance

var mesh_arr = []
export var n = 40 # number of grid
export var L = 10.0 # n * size of the grid 
var v = 0
export(int) var type
var enable = [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] #first one be pattern0 and unused

export var R = 4
export var a = 0.5

var vertices = PoolIntArray()
var mesh_vertices = PoolVector3Array()
var mesh_indices = PoolIntArray()
var direct = [Vector3(0, 0, 0), Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), 
			Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)]
			
	
func implicit_mesh(x, y, z):
	if type == 1 or type == 2:
		var F1 = (x * x + y * y + z * z + R * R - a * a) * (x * x + y * y + z * z + R * R - a * a) - 4 * R * R * (x * x + y * y)
		var F2 = (x * x + y * y + z * z + R * R - a * a) * (x * x + y * y + z * z + R * R - a * a) - 4 * R * R * (x * x + z * z)
		var F3 = (x * x + y * y + z * z + R * R - a * a) * (x * x + y * y + z * z + R * R - a * a) - 4 * R * R * (z * z + y * y)
		if type == 1:
			return F1 * F2 * F3 - 100
		else:
			return F2
	elif type == 0:
		return x * x + y * y + z * z - R * R

func _ready():
	mesh_arr.resize(Mesh.ARRAY_MAX)
	var size = L / n
	
	for w in range(n):
		for j in range(n):
			for i in range(n):
				var x = i * size - L / 2.0
				var y = j * size - L / 2.0
				var z = w * size - L / 2.0
				if implicit_mesh(x, y, z) >= 0:
					vertices.append(1)
				else:
					vertices.append(0)
	
	for w in range(n - 1):
		for j in range(n - 1):
			for i in range(n - 1):
				var check = check_cube(i, j, w) #[8vertices, cnt1]
				add_surface(check, i, j, w)	
							
	mesh_arr[Mesh.ARRAY_VERTEX] = mesh_vertices
	mesh_arr[Mesh.ARRAY_INDEX] = mesh_indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arr)
		
func redraw_surface():
	mesh_arr = []
	vertices = PoolIntArray()
	mesh_vertices = PoolVector3Array()
	mesh_indices = PoolIntArray()
	v = 0
	mesh_arr.resize(Mesh.ARRAY_MAX)
	while mesh.get_surface_count() > 0:
		mesh.surface_remove(0)
	var size = L / n
	
	for w in range(n):
		for j in range(n):
			for i in range(n):
				var x = i * size - L / 2.0
				var y = j * size - L / 2.0
				var z = w * size - L / 2.0
				if implicit_mesh(x, y, z) >= 0:
					vertices.append(1)
				else:
					vertices.append(0)
	
	for w in range(n - 1):
		for j in range(n - 1):
			for i in range(n - 1):
				var check = check_cube(i, j, w) #[8vertices, cnt1]
				add_surface(check, i, j, w)	
							
	mesh_arr[Mesh.ARRAY_VERTEX] = mesh_vertices
	mesh_arr[Mesh.ARRAY_INDEX] = mesh_indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arr)

func add_surface(check, i, j, w):
	var look_for = 1
	if check[-1] == 1 or check[-1] == 7:
		if check[-1] == 7: look_for = 0
		var ind = check.find(look_for, 0)
		pattern1(i, j, w, ind)
	elif check[-1] == 2 or check[-1] == 6:
		if check[-1] == 6: look_for = 0
		var ind1 = check.find(look_for, 0)
		var ind2 = check.find(look_for, ind1 + 1)
		var distance = (direct[ind1] - direct[ind2]).length_squared()
		if distance == 1:
			pattern2(i, j, w, ind1, ind2)
		elif distance == 2 or distance == 3:
			pattern3(i, j, w, ind1, ind2) #pattern3 == pattern10
	elif check[-1] == 3 or check[-1] == 5:
		if check[-1] == 5: look_for = 0
		var ind1 = check.find(look_for, 0)
		var ind2 = check.find(look_for, ind1 + 1)
		var ind3 = check.find(look_for, ind2 + 1)
		var L12 = direct[ind2] - direct[ind1]
		var L13 = direct[ind3] - direct[ind1]
		var L23 = direct[ind3] - direct[ind2]
		var Ls = [L12.length_squared(), L13.length_squared(), L23.length_squared()]
		if Ls.max() == 3:
			pattern11(i, j, w, ind1, ind2, ind3)
		elif Ls.max() == 2 and Ls.min() == 2:
			pattern12(i, j, w, ind1, ind2, ind3)
		elif Ls.max() == 2 and Ls.min() == 1:
			pattern4(i, j, w, ind1, ind2, ind3)
	elif check[-1] == 4:
		var ind1 = check.find(1, 0)
		var ind2 = check.find(1, ind1 + 1)
		var ind3 = check.find(1, ind2 + 1)
		var ind4 = check.find(1, ind3 + 1)
		var L12 = direct[ind2] - direct[ind1]
		var L13 = direct[ind3] - direct[ind1]
		var L14 = direct[ind4] - direct[ind1]
		var Ls = [L12.length_squared(), L13.length_squared(), L14.length_squared()]
		Ls.sort()
		var same_planar = (L12).cross(L13).dot(L14)
		if abs(same_planar) <= 0.00001:
			if Ls[-1] == 3:
				pattern13(i, j, w, ind1, ind2, ind3, ind4)
			else:
				pattern5(i, j, w, ind1, ind2, ind3, ind4)
		else:
			var pattern = check_four_not_planar(ind1, ind2, ind3, ind4)
			if pattern != -1:
				#pattern9 = pattern14
				call("pattern" + str(pattern), i, j, w, ind1, ind2, ind3, ind4)
				
#pattern0 skipped
func pattern1(i, j, w, ind):
	if enable[1] == 0:
		return 0
	var p = To3d(Vector3(i, j, w) + direct[ind])
	var near = find_near(ind)
	mesh_vertices.append(p + near[0])
	mesh_indices.append(v)
	mesh_vertices.append(p + near[1])
	mesh_indices.append(v + 1)
	mesh_vertices.append(p + near[2])
	mesh_indices.append(v + 2)
	v += 3

func pattern2(i, j, w, ind1, ind2):
	if enable[2] == 0:
		return 0
	var p1 = To3d(Vector3(i, j, w) + direct[ind1])
	var p2 = To3d(Vector3(i, j, w) + direct[ind2])
	var near1 = find_near(ind1)
	var near2 = find_near(ind2)
	var vert = []
	for k in range(3):
		if p1[k] == p2[k]:
			vert.append(p1 + near1[k])
			vert.append(p2 + near2[k])
			
	add_rectangle(vert)
			

func pattern3(i, j, w, ind1, ind2):
	var p1 = To3d(Vector3(i, j, w) + direct[ind1])
	var p2 = To3d(Vector3(i, j, w) + direct[ind2])
	if (p1 - p2).length_squared() == 2 * (L / n) * (L / n):
		if enable[3] == 0:
			return 0
	elif enable[10] == 0:
		return 0
	var near1 = find_near(ind1)
	var near2 = find_near(ind2)
	var vert = [p1 + near1[0], p1 + near1[1], p1 + near1[2], p2 + near2[0], p2 + near2[1], p2 + near2[2]]
	for k in range(len(vert)):
		mesh_vertices.append(vert[k])
		mesh_indices.append(v)
		v += 1

func pattern4(i, j, w, ind1, ind2, ind3):
	if enable[4] == 0:
		return 0
	var p1 = To3d(Vector3(i, j, w) + direct[ind1])
	var p2 = To3d(Vector3(i, j, w) + direct[ind2])
	var p3 = To3d(Vector3(i, j, w) + direct[ind3])
	var near1 = find_near(ind1)
	var near2 = find_near(ind2)
	var near3 = find_near(ind3)
	var dis12 = (p1 - p2).length_squared();
	var dis13 = (p1 - p3).length_squared();
	if dis12 == dis13:
		var tmpp = p2
		var tmpn = near2
		p2 = p1
		near2 = near1
		p1 = tmpp
		near1 = tmpn
	elif dis13 == (L / n) * (L / n):
		var tmpp = p2
		var tmpn = near2
		p2 = p3
		near2 = near3
		p3 = tmpp
		near3 = tmpn
	
	var near2_tmp = []
	for nn in near2:
		near2_tmp.append(nn + p2)
	var vert = [0, 0]
	
	var NORMAL = ((p2 - p1).cross(p3 - p1)).normalized()
	var normal = NORMAL * L / (n * 2)
	var near = find_near(ind1)
	
	if not(normal in near):
		normal = -1 * normal
		NORMAL = -1 * NORMAL
	
	for k in range(3):
		if not ((p1 + near1[k]) in near2_tmp):
			if abs(near1[k].dot(NORMAL)) != near1[k].length():
				vert[0] = p1 + near1[k]
		if not ((p3 + near3[k]) in near2_tmp):
			if abs(near1[k].dot(NORMAL)) != near3[k].length():
				vert[1] = p3 + near3[k]
	
	mesh_vertices.append(p1 + normal)
	mesh_indices.append(v)
	mesh_vertices.append(p3 + normal)
	mesh_indices.append(v + 1)
	mesh_vertices.append(vert[0])
	mesh_indices.append(v + 2)
	mesh_vertices.append(vert[0])
	mesh_indices.append(v + 3)
	mesh_vertices.append(p3 + normal)
	mesh_indices.append(v + 4)
	mesh_vertices.append(vert[1])
	mesh_indices.append(v + 5)
	v += 6

	mesh_vertices.append(p1 + normal)
	mesh_indices.append(v)
	mesh_vertices.append(p2 + normal)
	mesh_indices.append(v + 1)
	mesh_vertices.append(p3 + normal)
	mesh_indices.append(v + 2)
	v += 3
	

func pattern5(i, j, w, ind1, ind2, ind3, ind4):
	if enable[5] == 0:
		return 0
	var p1 = To3d(Vector3(i, j, w) + direct[ind1])
	var p2 = To3d(Vector3(i, j, w) + direct[ind2])
	var p3 = To3d(Vector3(i, j, w) + direct[ind3])
	var p4 = To3d(Vector3(i, j, w) + direct[ind4])
	var normal = ((p2 - p1).cross(p3 - p1)).normalized()
	normal = normal * L / (n * 2)
	var near = find_near(ind1)
	if not(normal in near):
		normal = -1 * normal
	var vert = [p1 + normal, p2 + normal, p3 + normal, p4 + normal]
	add_rectangle(vert)
	
func pattern6(i, j, w, ind1, ind2, ind3, ind4):
	if enable[6] == 0:
		return 0
	var ps = [ind1, ind2, ind3, ind4]
	for pi in range(len(ps)):
		var p1 = To3d(Vector3(i, j, w) + direct[ps[pi]])
		var p2 = To3d(Vector3(i, j, w) + direct[ps[(pi + 1) % 4]])
		var p3 = To3d(Vector3(i, j, w) + direct[ps[(pi + 2) % 4]])
		var p4 = To3d(Vector3(i, j, w) + direct[ps[(pi + 3) % 4]])
		var dis12 = (p1 - p2).length_squared()
		var dis13 = (p1 - p3).length_squared()
		var dis14 = (p1 - p4).length_squared()
		#let p4 be single point
		if dis12 + dis13 + dis14 == 7:
			var tmp = ind4
			ind4 = ps[pi]
			ps[pi] = tmp
			ind2 = ps[1]
			ind3 = ps[2]
			ind1 = ps[0]
			break
	var p1 = To3d(Vector3(i, j, w) + direct[ind1])
	var p2 = To3d(Vector3(i, j, w) + direct[ind2])
	var p3 = To3d(Vector3(i, j, w) + direct[ind3])
	var p4 = To3d(Vector3(i, j, w) + direct[ind4])
	var near1 = find_near(ind1)
	var near2 = find_near(ind2)
	var near3 = find_near(ind3)
	var near4 = find_near(ind4)

	var dis12 = (p1 - p2).length_squared();
	var dis13 = (p1 - p3).length_squared();
	if dis12 == dis13:
		var tmpp = p2
		var tmpn = near2
		p2 = p1
		near2 = near1
		p1 = tmpp
		near1 = tmpn
	elif dis13 == (L / n) * (L / n):
		var tmpp = p2
		var tmpn = near2
		p2 = p3
		near2 = near3
		p3 = tmpp
		near3 = tmpn
	
	var near2_tmp = []
	for nn in near2:
		near2_tmp.append(nn + p2)
	var vert = [0, 0]
	
	var NORMAL = ((p2 - p1).cross(p3 - p1)).normalized()
	var normal = NORMAL * L / (n * 2)
	var near = find_near(ind1)
	
	if not(normal in near):
		normal = -1 * normal
		NORMAL = -1 * NORMAL
	
	for k in range(3):
		if not ((p1 + near1[k]) in near2_tmp):
			if abs(near1[k].dot(NORMAL)) != near1[k].length():
				vert[0] = p1 + near1[k]
		if not ((p3 + near3[k]) in near2_tmp):
			if abs(near1[k].dot(NORMAL)) != near3[k].length():
				vert[1] = p3 + near3[k]
	
	mesh_vertices.append(p1 + normal)
	mesh_indices.append(v)
	mesh_vertices.append(p3 + normal)
	mesh_indices.append(v + 1)
	mesh_vertices.append(vert[0])
	mesh_indices.append(v + 2)
	mesh_vertices.append(vert[0])
	mesh_indices.append(v + 3)
	mesh_vertices.append(p3 + normal)
	mesh_indices.append(v + 4)
	mesh_vertices.append(vert[1])
	mesh_indices.append(v + 5)
	v += 6
	
	mesh_vertices.append(p1 + normal)
	mesh_indices.append(v)
	mesh_vertices.append(p2 + normal)
	mesh_indices.append(v + 1)
	mesh_vertices.append(p3 + normal)
	mesh_indices.append(v + 2)
	v += 3
	
	vert = [p4 + near4[0], p4 + near4[1], p4 + near4[2]]
	for k in range(len(vert)):
		mesh_vertices.append(vert[k])
		mesh_indices.append(v)
		v += 1

func pattern7(i, j, w, ind1, ind2, ind3, ind4):
	if enable[7] == 0:
		return 0
	var p1 = To3d(Vector3(i, j, w) + direct[ind1])
	var p2 = To3d(Vector3(i, j, w) + direct[ind2])
	var p3 = To3d(Vector3(i, j, w) + direct[ind3])
	var p4 = To3d(Vector3(i, j, w) + direct[ind4])
	var near1 = find_near(ind1)
	var near2 = find_near(ind2)
	var near3 = find_near(ind3)
	var near4 = find_near(ind4)
	var vert = [p1 + near1[0], p1 + near1[1], p1 + near1[2], 
				p2 + near2[0], p2 + near2[1], p2 + near2[2], 
				p3 + near3[0], p3 + near3[1], p3 + near3[2],
				p4 + near4[0], p4 + near4[1], p4 + near4[2]]
	for k in range(len(vert)):
		mesh_vertices.append(vert[k])
		mesh_indices.append(v)
		v += 1

func pattern8(i, j, w, ind1, ind2, ind3, ind4):
	if enable[8] == 0:
		return 0
	var p1 = To3d(Vector3(i, j, w) + direct[ind1])
	var p2 = To3d(Vector3(i, j, w) + direct[ind2])
	var p3 = To3d(Vector3(i, j, w) + direct[ind3])
	var p4 = To3d(Vector3(i, j, w) + direct[ind4])
	var near1 = find_near(ind1)
	var near2 = find_near(ind2)
	var near3 = find_near(ind3)
	var near4 = find_near(ind4)
	var p = [p1, p2, p3, p4]
	var near = [near1, near2, near3, near4]
	var tmp = []
	var dict = {}
	for i in range(len(p)):
		for j in near[i]:
			var cur = p[i] + j
			tmp.append(cur)
			if dict.has(cur):
				dict[cur] += 1
			else:
				dict[cur] = 1
	var vert = []
	for i in tmp:
		if dict[i] == 1:
			vert.append(i)
	add_hexagon(vert)
	
			
func pattern9(i, j, w, ind1, ind2, ind3, ind4): #pattern9 = pattern14
	var size = L / n
	var p1 = To3d(Vector3(i, j, w) + direct[ind1])
	var p2 = To3d(Vector3(i, j, w) + direct[ind2])
	var p3 = To3d(Vector3(i, j, w) + direct[ind3])
	var p4 = To3d(Vector3(i, j, w) + direct[ind4])
	var near1 = find_near(ind1)
	var near2 = find_near(ind2)
	var near3 = find_near(ind3)
	var near4 = find_near(ind4)
	var p = [p1, p2, p3, p4]
	var near = [near1, near2, near3, near4]
	var far_i1 = -1
	var far_i2
	var near_i1
	var near_i2
	for ii in range(3):
		for jj in range(4):
			if (p[ii] - p[jj]).length_squared() == 3 * size * size:
				far_i1 = ii
				far_i2 = jj	
				break
		if far_i1 != -1: break
	for ii in range(4):
		if (p[ii] - p[far_i1]).length_squared() == 1 * size * size:
			near_i1 = ii
			break
	near_i2 = 6 - (far_i1 + far_i2 + near_i1)
	var test = (p[near_i2] - p[near_i1]).cross(p[far_i1] - p[near_i1])
	test = test.dot(p[far_i2] - p[near_i2])
	if test < 0:
		if enable[14] == 0:
			return 0
	elif enable[9] == 0:
		return 0
	#[far_i1_same, far_i1_dif, far_i2_same, far_i2_dif, near_i1_p, near_i2_p] #far_i1_same: same direction with far_i2 - near_i2
	var p_on_grid = [0, 0, 0, 0, 0, 0]
	for ii in range(3):
		if near[far_i1][ii].cross(p[far_i2] - p[near_i2]) == Vector3.ZERO:
			p_on_grid[0] = p[far_i1] + near[far_i1][ii]
		elif near[far_i1][ii].cross(p[near_i1] - p[near_i2]) == Vector3.ZERO:
			p_on_grid[1] = p[far_i1] + near[far_i1][ii]
			
		if near[far_i2][ii].cross(p[far_i1] - p[near_i1]) == Vector3.ZERO:
			p_on_grid[2] = p[far_i2] + near[far_i2][ii]
		elif near[far_i2][ii].cross(p[near_i2] - p[near_i1]) == Vector3.ZERO:
			p_on_grid[3] = p[far_i2] + near[far_i2][ii]
		
		if near[near_i1][ii].cross(p[far_i2] - p[near_i2]) == Vector3.ZERO:
			p_on_grid[4] = p[near_i1] + near[near_i1][ii]
		if near[near_i2][ii].cross(p[far_i1] - p[near_i1]) == Vector3.ZERO:
			p_on_grid[5] = p[near_i2] + near[near_i2][ii]
	
	mesh_vertices.append(p_on_grid[0])
	mesh_indices.append(v)
	mesh_vertices.append(p_on_grid[1])
	mesh_indices.append(v + 1)
	mesh_vertices.append(p_on_grid[4])
	mesh_indices.append(v + 2)
	mesh_vertices.append(p_on_grid[2])
	mesh_indices.append(v + 3)
	mesh_vertices.append(p_on_grid[3])
	mesh_indices.append(v + 4)
	mesh_vertices.append(p_on_grid[4])
	mesh_indices.append(v + 5)
	mesh_vertices.append(p_on_grid[1])
	mesh_indices.append(v + 6)
	mesh_vertices.append(p_on_grid[2])
	mesh_indices.append(v + 7)
	mesh_vertices.append(p_on_grid[4])
	mesh_indices.append(v + 8)
	mesh_vertices.append(p_on_grid[1])
	mesh_indices.append(v + 9)
	mesh_vertices.append(p_on_grid[2])
	mesh_indices.append(v + 10)
	mesh_vertices.append(p_on_grid[5])
	mesh_indices.append(v + 11)
	v += 12
	
						
#pattern10 == pattern3
	
func pattern11(i, j, w, ind1, ind2, ind3):
	if enable[11] == 0:
		return 0
	var size2 = (L / n) * (L / n)
	var p1 = To3d(Vector3(i, j, w) + direct[ind1])
	var p2 = To3d(Vector3(i, j, w) + direct[ind2])
	var p3 = To3d(Vector3(i, j, w) + direct[ind3])
	var dis12 = (p1 - p2).length_squared()
	var dis13 = (p1 - p3).length_squared()
	#let p1 be single point
	if (dis12 == 1 * size2 and dis13 == 2 * size2) or (dis12 == 1 * size2 and dis13 == 3 * size2):
		var tmp = ind1
		ind1 = ind3
		ind3 = tmp
	elif (dis12 == 2 * size2 and dis13 == 1 * size2) or (dis12 == 3 * size2 and dis13 == 1 * size2):
		var tmp = ind1
		ind1 = ind2
		ind2 = tmp
		
	p1 = To3d(Vector3(i, j, w) + direct[ind1])
	p2 = To3d(Vector3(i, j, w) + direct[ind2])
	p3 = To3d(Vector3(i, j, w) + direct[ind3])
	var near1 = find_near(ind1)
	var near2 = find_near(ind2)
	var near3 = find_near(ind3)
	var vert = []
	for k in range(3):
		if p2[k] == p3[k]:
			vert.append(p2 + near2[k])
			vert.append(p3 + near3[k])
			
	add_rectangle(vert)
	
	vert = [p1 + near1[0], p1 + near1[1], p1 + near1[2]]
	for k in range(len(vert)):
		mesh_vertices.append(vert[k])
		mesh_indices.append(v)
		v += 1
		
func pattern12(i, j, w, ind1, ind2, ind3):
	if enable[12] == 0:
		return 0
	var p1 = To3d(Vector3(i, j, w) + direct[ind1])
	var p2 = To3d(Vector3(i, j, w) + direct[ind2])
	var p3 = To3d(Vector3(i, j, w) + direct[ind3])
	var near1 = find_near(ind1)
	var near2 = find_near(ind2)
	var near3 = find_near(ind3)
	var vert = [p1 + near1[0], p1 + near1[1], p1 + near1[2], 
				p2 + near2[0], p2 + near2[1], p2 + near2[2], 
				p3 + near3[0], p3 + near3[1], p3 + near3[2]]
	for k in range(len(vert)):
		mesh_vertices.append(vert[k])
		mesh_indices.append(v)
		v += 1

func pattern13(i, j, w, ind1, ind2, ind3, ind4):
	if enable[13] == 0:
		return 0
	var p1 = To3d(Vector3(i, j, w) + direct[ind1])
	var p2 = To3d(Vector3(i, j, w) + direct[ind2])
	var p3 = To3d(Vector3(i, j, w) + direct[ind3])
	var p4 = To3d(Vector3(i, j, w) + direct[ind4])
	var near1 = find_near(ind1)
	var near2 = find_near(ind2)
	var near3 = find_near(ind3)
	var near4 = find_near(ind4)
	if (p1 - p2).length_squared() == (L / n) * (L / n):
		var tmpp = p2
		var tmpn = near2
		p2 = p3
		near2 = near3
		p3 = tmpp
		near3 = tmpn
	if (p1 - p4).length_squared() == (L / n) * (L / n):
		var tmpp = p4
		var tmpn = near4
		p4 = p3
		near4 = near3
		p3 = tmpp
		near3 = tmpn
	var vert1 = []
	var vert2 = []
	for k in range(3):
		if p1[k] == p3[k]:
			vert1.append(p1 + near1[k])
			vert1.append(p3 + near3[k])
		if p2[k] == p4[k]:
			vert2.append(p2 + near2[k])
			vert2.append(p4 + near4[k])
	add_rectangle(vert1)
	add_rectangle(vert2)
	

func index(i, j, w):
	return i + j * n + w * n * n
	
func find_near(ind):
	var size = L / (n * 2)
	var near = [Vector3(size, 0, 0),  Vector3(0, size, 0), Vector3(0, 0, size)]
	for i in range(3):
		if direct[ind][i] == 1:
			near[i] = -1 * near[i]
	return near
	
func add_rectangle(vert):
	assert(vert.size() == 4, "ERROR: You need 4 points to draw rectangle.")
	var max_len = 0
	var farest = 0
	var p1 = -1
	var p2 = -1
	for i in range(1, 4):
		var cur_l = (vert[0] - vert[i]).length_squared()
		if max_len < cur_l:
			farest = i
			max_len = cur_l
	for i in range(1, 4):
		if i != farest:
			if p1 == -1:
				p1 = i
			else:
				p2 = i
			
	mesh_vertices.append(vert[0])
	mesh_indices.append(v)
	mesh_vertices.append(vert[farest])
	mesh_indices.append(v + 1)					
	mesh_vertices.append(vert[p1])
	mesh_indices.append(v + 2)
	mesh_vertices.append(vert[0])
	mesh_indices.append(v + 3)
	mesh_vertices.append(vert[farest])
	mesh_indices.append(v + 4)					
	mesh_vertices.append(vert[p2])
	mesh_indices.append(v + 5)
	v += 6

func add_hexagon(vert):
	assert(vert.size() == 6, "ERROR: You need 6 points to draw hexagon.")
	var center = Vector3.ZERO
	for vv in vert:
		center += vv
	center /= 6
	var vec1
	var vec2
	var d
	
	vec1 = vert[0] - vert[1]
	vec2 = vert[2] - vert[3]
	d = vec1.dot(vec2)
	if d > 0:
		var tmp = vert[2]
		vert[2] = vert[3]
		vert[3] = tmp
		
	vec1 = vert[2] - vert[3]
	vec2 = vert[4] - vert[5]
	d = vec1.dot(vec2)
	if d > 0:
		var tmp = vert[4]
		vert[4] = vert[5]
		vert[5] = tmp
	
	vec1 = vert[0] - vert[1]
	vec2 = vert[1] - vert[2]
	d = vec1.dot(vec2)
	if d < 0:
		var tmp = vert[0]
		vert[0] = vert[1]
		vert[1] = tmp
		tmp = vert[2]
		vert[2] = vert[3]
		vert[3] = tmp
		tmp = vert[4]
		vert[4] = vert[5]
		vert[5] = tmp
	
	for e in range(5):
		mesh_vertices.append(vert[e])
		mesh_indices.append(v)
		mesh_vertices.append(vert[e + 1])
		mesh_indices.append(v + 1)					
		mesh_vertices.append(center)
		mesh_indices.append(v + 2)
		v += 3
		
	mesh_vertices.append(vert[5])
	mesh_indices.append(v)
	mesh_vertices.append(vert[0])
	mesh_indices.append(v + 1)					
	mesh_vertices.append(center)
	mesh_indices.append(v + 2)
	v += 3
	
func check_cube(i, j, w):
	var checked = []
	var cnt1 = 0
	var origin = Vector3(i, j, w)
	for d in direct:
		var cur = origin + d
		var ind = index(cur[0], cur[1], cur[2])
		checked.append(vertices[ind])
		if vertices[ind] == 1:
			cnt1 += 1
	checked.append(cnt1)
	return checked

func check_four_not_planar(ind1, ind2, ind3, ind4):
	var pt = [direct[ind1], direct[ind2], direct[ind3], direct[ind4]]
	var lengths = []
	for i in range(4):
		var tmp = 0
		for j in range(4):
			tmp += (pt[i] - pt[j]).length_squared()
		lengths.append(tmp)
	var length_sum = sum(lengths)
	if length_sum == 22:
		return 6
	elif length_sum == 24:
		return 7
	elif length_sum == 18:
		return 8
	elif length_sum == 20:
		return 9
	return -1
	
func sum(l):
	var ret = 0
	for i in l:
		ret += i
	return ret

func To3d(vet: Vector3):
	var size = L / n
	vet = vet * size - Vector3(L / 2.0, L / 2.0, L / 2.0)
	return vet
	
func change_enable(ind):
	if enable[ind] == 1:
		enable[ind] = 0
	else:
		enable[ind] = 1
	redraw_surface()
