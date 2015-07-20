module ws.file.bbatch;

import
	std.conv,
	std.stdio,
	std.file,
	std.path,
	std.c.string,
	ws.decode,
	ws.file.obj;


alias Vertex = float[3 + 3 + 2];

struct MaterialInfo {
	string name;
	string[string] attributes;
}

struct VertMat {
	Vertex[] vertices;
	MaterialInfo material;
}


class BinaryBatch {

	struct Header {
		long vers;
		long count;
	}

	string path;
	VertMat[] data;

	private this(){}

	this(string path){
		MaterialInfo[string] materials;
		Decode.file("models/" ~ path.setExtension("bbm"), (name, content, b){
			auto m = MaterialInfo(name);
			Decode.text(content, (attr, val, b){
				m.attributes[attr] = val;
			});
			materials[name] = m;
		});

		auto file = File("models/" ~ path, "r");
		Header[1] header;
		file.rawRead(header);
		for(int i=0; i<header[0].count; i++){
			long len;
			VertMat vm;
			char[] name;
			// material
			file.rawRead((&len)[0..1]);
			assert(name.length < file.size);
			name.length = cast(size_t)len;
			file.rawRead(name);
			vm.material = materials[to!string(name)];
			// vertices
			file.rawRead((&len)[0..1]);
			assert(len < file.size);
			vm.vertices.length = cast(size_t)len;
			file.rawRead(vm.vertices);
			data ~= vm;
		}
	}

	void save(){
		auto file = File(path, "wb");
		Header[1] header = [Header(1, data.length)];
		file.rawWrite(header);
		foreach(vm; data){
			file.rawWrite([cast(long)vm.material.name.length]);
			file.rawWrite(vm.material.name);
			file.rawWrite([cast(long)vm.vertices.length]);
			file.rawWrite(vm.vertices);
		}
	}

	static BinaryBatch fromObj(string path){
		auto bb = new BinaryBatch;
		bb.path = "models/" ~ path[0..$-3] ~ "bb";
		auto mdl = new OBJ("models/" ~ path);
		foreach(object; mdl.objects){
			foreach(material; object.materials.values){
				VertMat vm;
				vm.material = MaterialInfo(material.name);
				foreach(polygon; material.polygons){
					foreach(vertex; polygon.vertices){
						Vertex vert;
						vert[0..3] = vertex.pos;
						vert[3..6] = vertex.normal;
						vert[6..8] = vertex.uvw.data[0..2];
						vm.vertices ~= vert;
					}
				}
				bb.data ~= vm;
			}
		}
		return bb;
	}

}
