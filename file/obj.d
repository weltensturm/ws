
module ws.file.obj;

import std.conv;

import ws.math.vector;
import ws.decode;
import ws.io;
import ws.string;


__gshared:


class MTL {
	public:
		class Material {
			this(string n){
				name = n;
			}
			string name;
			Vector!3 ambient;
			Vector!3 diffuse;
			Vector!3 specular;
			double dissolve;
			int illum;
			string mapDiffuse;
			string mapAmbient;
			string mapSpecular;
			string mapBump;
			string ext;
		};
		Material[] mtls;

		void load(string path){
			Material currentMat;
			MTL currentMtl;
			currentMtl = this;
			try Decode.file(path, delegate(string command, string content, bool b){
				switch(command){
					case "newmtl":
						currentMat = new Material(content);
						currentMtl.mtls ~= currentMat;
						break;
							
					case "Ka":
						double[] v = toNumbers(content);
						for(size_t i=0; i<v.length; i++)
							currentMat.ambient[i] = v[i];
						break;

					case "Kd":
						double[] v = toNumbers(content);
						for(size_t i=0; i<v.length; i++)
							currentMat.diffuse[i] = v[i];
						break;

					case "Ks":
						double[] v = toNumbers(content);
						for(size_t i=0; i<v.length; i++)
							currentMat.specular[i] = v[i];
						break;

					case "illum":
						currentMat.illum = to!int(content);
						break;

					case "d":
						currentMat.dissolve = to!double(content);
						break;

					case "map_Ka":
						currentMat.mapAmbient = content;
						break;

					case "map_Kd":
						currentMat.mapDiffuse = content;
						break;

					case "map_Ks":
						currentMat.mapSpecular = content;
						break;
					
					case "map_bump":
					case "bump":
						currentMat.mapBump = content;
						break;
					
					case "extern":
						currentMat.ext = content;
						break;
						
					default:
						break;//writeln("Unknown command: " ~ command);

				}

			});
			catch(Exception e)
				writeln("Failed to load MTL \"%\"\n", path, e);
		}
};


class OBJ {
		
	/+
	Decodes a wavefront obj file and stores it in this format:
	mtllibs:
	objects:
		name
		materials:
			name
			vertcount
			polygons:
				group
				smoothinggroup
				vertices:
					pos
					uvw
					normal
	+/

	this(string name){
		dataVectors = [[], [], []];

		currentObject = null;
		currentPath = "";
		if(name.findLast('/') < name.length)
			currentPath = name[0..name.findLast('/')+1];

		currentObject = new OBJ.CObject("__default__");
		objects["__default__"] = currentObject;
	
		try Decode.file(name, delegate(string cmd, string content, bool block){
			switch(cmd){
				case "v":
					Vector!3 t;
					foreach(i, n; toNumbers(content)){
						if(i>2) break;
						t[i] = n;
					}
					dataVectors[0] ~= t;
				break;
			
				case "vt":
					Vector!3 t;
					foreach(i, n; toNumbers(content)){
						if(i>2) break;
						t[i] = n;
					}
					dataVectors[1] ~= t;
				break;
			
				case "vn":
					Vector!3 t;
					foreach(i, n; toNumbers(content)){
						if(i>2) break;
						t[i] = n;
					}
					dataVectors[2] ~= t;
				break;
			
				case "f":
					auto f = new OBJ.Polygon;
					currentMaterial.polygons ~= f;
					foreach(i, string s; content.split(' ')){
						if(s == "") continue;
						if(i > 2){
							// Convert all polygons with more than 3 vertices to triangles
							f.vertices ~= f.vertices[$-3];
							f.vertices ~= f.vertices[$-2];
							currentMaterial.vertcount += 2;
						}
						auto e = new OBJ.Vertex;
						f.vertices ~= e;
						string[] vertSplit = s.split('/');
						currentMaterial.vertcount++;
						for(size_t mode = 0; mode < 3; mode++){
							if(mode >= vertSplit.length || vertSplit[mode] == ""){
								// fill values that are not given
								e[mode] = (mode==1 ? Vector!3(e.pos[1], e.pos[0]+e.pos[2], 0)/100 : Vector!3(0,1,0));
							}else{
								size_t idx = to!size_t(vertSplit[mode]);
								if(idx<1 || idx>dataVectors[mode].length)
									throw new Exception(tostring("Model has dangerous % index (%)", (mode==0 ? "vertex" : (mode==1 ? "uvw" : "normal")), idx));
								else
									e[mode] = dataVectors[mode][idx-1];
							}
						}
					}
				break;
			
				case "mtllib":
					auto m = new MTL;
					m.load(currentPath ~ content);
					mtllibs ~= m;
				break;
			
				case "usemtl":
					if(content in currentObject.materials){
						currentMaterial = currentObject.materials[content];
						return;
					}
					currentMaterial = new OBJ.Material(content);
					currentObject.materials[content] = currentMaterial;
				break;
			
				case "o":
					if(content in objects){
						currentObject = objects[content];
						return;
					}
					currentObject = new OBJ.CObject(content);
					objects[content] = currentObject;
				break;
			
				case "g":
					currentGroup = content;
				break;

				case "s":
					if(content == "off")
						currentSmooth = 0;
					else
						currentSmooth = to!long(content);
				break;
				
				default:
					options[cmd] = content;
					if(cmd !in unknownCommands){
						writeln("OBJ \"%\": Command not recognized: \"%\"", name, cmd);
						unknownCommands[cmd] = true;
					}
				}
		});
		catch(Exception e){
			throw new Exception("Failed to decode \"" ~ name ~ "\", " ~ e.toString);
		}
	}

	static class Vertex {
		Vector!3 pos;
		Vector!3 uvw;
		Vector!3 normal;
		ref Vector!3 opIndex(long i){
			switch(i){
				case 0: return pos;
				case 1: return uvw;
				case 2: return normal;
				default: return pos;
			}
		}
	}

	static class Polygon {
		string group;
		long smoothinggroup;
		Vertex[] vertices;
	}

	static class Material {
		this(string n){
			name = n;
		}
		string name;
		int vertcount = 0;
		Polygon[] polygons;
	}

	static class CObject {
		this(string n){
			name = n;
		}
		string name;
		Material[string] materials;
	}

	MTL[] mtllibs;

	CObject[string] objects;

	bool[string] unknownCommands;
	string[string] options;
	Vector!3[][] dataVectors;
	Material currentMaterial;
	CObject currentObject;
	string currentGroup;
	long currentSmooth;
	string currentPath;
	
}



class DataOBJ {
	Vector!3[] vertices;
	Vector!3[] texCoords;
	Vector!3[] normals;
	Polygon[] polygons;

	this(string name){

		currentObject = null;
		currentPath = "";
		if(name.findLast('/') < name.length)
			currentPath = name[0..name.findLast('/')+1];

		currentObject = new DataOBJ.CObject("__default__");
		objects["__default__"] = currentObject;
	
		try Decode.file(name, delegate(string cmd, string content, bool block){
			switch(cmd){
				case "v":
					Vector!3 t;
					foreach(i, n; toNumbers(content)){
						if(i>2) break;
						t[i] = n;
					}
					vertices ~= t;
				break;
			
				case "vt":
					Vector!3 t;
					foreach(i, n; toNumbers(content)){
						if(i>2) break;
						t[i] = n;
					}
					texCoords ~= t;
				break;
			
				case "vn":
					Vector!3 t;
					foreach(i, n; toNumbers(content)){
						if(i>2) break;
						t[i] = n;
					}
					normals ~= t;
				break;
			
				case "f":
					Polygon f = [];
					foreach(i, string s; content.split(' ')){
						if(s == "") continue;
						f ~= [-1, -1, -1];
						string[] vertSplit = s.split('/');
						currentMaterial.vertcount++;
						for(size_t mode = 0; mode < 3; mode++){
							if(mode < vertSplit.length && vertSplit[mode] != "")
								f[i][mode] = to!size_t(vertSplit[mode])-1;
						}
					}
					currentMaterial.polygons ~= f;
				break;

				case "mtllib":
					auto m = new MTL;
					m.load(currentPath ~ content);
					mtllibs ~= m;
				break;
			
				case "usemtl":
					if(content in currentObject.materials){
						currentMaterial = currentObject.materials[content];
						return;
					}
					currentMaterial = new DataOBJ.Material(content);
					currentObject.materials[content] = currentMaterial;
				break;
			
				case "o":
				case "g":
					if(content in objects){
						currentObject = objects[content];
						return;
					}
					currentObject = new DataOBJ.CObject(content);
					objects[content] = currentObject;
				break;
			
				//case "g":
				//	currentGroup = content;
				//break;

				case "s":
					if(content == "off")
						currentSmooth = 0;
					else
						currentSmooth = to!long(content);
				break;
				
				default:
					options[cmd] = content;
			}
		});
		catch(Exception e){
			throw new Exception("Failed to decode \"" ~ name ~ "\"", e);
		}
	}
	
	alias size_t[3][] Polygon; // [vertIndex, normalIndex, texIndex]
	

	static class Material {
		this(string n){
			name = n;
		}
		string name;
		int vertcount = 0;
		Polygon[] polygons;
	}

	static class CObject {
		this(string n){
			name = n;
		}
		string name;
		Material[string] materials;
	}

	MTL[] mtllibs;

	CObject[string] objects;

	string[string] options;
	Material currentMaterial;
	CObject currentObject;
	string currentGroup;
	long currentSmooth;
	string currentPath;
	
}
