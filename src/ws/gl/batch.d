module ws.gl.batch;

import
	std.algorithm,
	std.conv,
	ws.gl.gl,
	ws.gl.context,
	ws.exception,
	ws.io;

__gshared:


struct Layout {
	uint target;
	uint size;
}


class Batch {

	enum tex2 = [Layout(gl.attributeTexture, 2)];
	enum vert3 = [Layout(gl.attributeVertex, 3)];
	enum color4 = [Layout(gl.attributeColor, 4)];
	enum normal3 = [Layout(gl.attributeNormal, 3)];

	alias float[2] Tex;
	alias float[3] Vec;
	alias float[4] Color;
	
	this(GlContext context, uint type, Layout[] layout, float[] data){
		this.context = context;
		uint line;
		foreach(l; layout)
			line += l.size;
		assert(data.length % line == 0, "Batch data is not divisible by row length");
		begin(cast(uint)(data.length/line), type);
		foreach(i; 0..vertexCount){
			auto d = data[i*line .. (i+1)*line];
			int consumed = 0;
			foreach(l; layout){
				add(l.target, d[consumed..consumed+l.size]);
				consumed += l.size;
			}
			currentVert++;
		}
		finish;
	}

	void begin(int verts, uint type = GL_TRIANGLES){
		vertexCount = verts;
		currentVert = 0;
		this.type = type;
		context.genVertexArrays(1, cast(uint*)&vao);
		context.bindVertexArray(vao);
	}
	
	void finish(){
		assert(!done);
		foreach(array; arrays){
			context.bindBuffer(GL_ARRAY_BUFFER, array.globj);
			context.unmapBuffer(GL_ARRAY_BUFFER);
		}

		context.bindVertexArray(vao);

		foreach(array; arrays){
			context.bindBuffer(GL_ARRAY_BUFFER, array.globj);
			context.enableVertexAttribArray(array.attributeId),
			context.vertexAttribPointer(array.attributeId, array.size, GL_FLOAT, cast(ubyte)GL_FALSE, 0, null);
		}

		done = true;
		context.bindVertexArray(0);
	}
	
	void draw(){
		if(!done)
			return;
		context.bindVertexArray(vao);
		context.drawArrays(type, 0, vertexCount);
		//glBindVertexArray(0);
	}

	void add(Vec pos){
		add(gl.attributeVertex, pos[]);
		currentVert++;
	}

	void addPoint(Vec pos, Color col){
		add(gl.attributeVertex, pos[]);
		add(gl.attributeColor, col);
		currentVert++;
	}

	void addPoint(Vec pos, Vec normal){
		add(gl.attributeVertex, pos[]);
		add(gl.attributeNormal, normal[]);
		currentVert++;
	}

	void addPoint(Vec pos, Vec normal, Color col){
		add(gl.attributeVertex, pos[]);
		add(gl.attributeNormal, normal[]);
		add(gl.attributeColor, col);
		currentVert++;
	}

	void addPoint(Vec pos, Tex t){
		add(gl.attributeVertex, pos[]);
		add(gl.attributeTexture, t);
		currentVert++;
	}

	void addPoint(Vec pos, Vec normal, Tex t){
		add(gl.attributeVertex, pos[]);
		add(gl.attributeNormal, normal[]);
		add(gl.attributeTexture, t);
		currentVert++;
	}

	/*~this(){
		glDeleteVertexArrays(1, &vao);
	}*/
	
	void updateVertices(float[] data, size_t pos = 0, size_t length = 1){
		context.bindBuffer(GL_ARRAY_BUFFER, arrays[gl.attributeVertex].globj);
		context.bufferSubData(GL_ARRAY_BUFFER, pos*3*float.sizeof, length*3*float.sizeof, data.ptr);
	} 
	
	protected:
		
		GlContext context;

		uint vao;
		uint type;
		
		bool done = false;
		int vertexCount = 0;
		int currentVert = 0;
		
		class Array {
			this(uint size, uint attributeId){
				assert(!done);
				assert(vao);
				this.size = size;
				this.attributeId = attributeId;
				context.genBuffers(1, cast(uint*)&globj);
				context.bindBuffer(GL_ARRAY_BUFFER, globj);
				context.bufferData(GL_ARRAY_BUFFER, float.sizeof*size*vertexCount, null, GL_DYNAMIC_DRAW);
				context.bindBuffer(GL_ARRAY_BUFFER, globj);
				array = cast(float*)context.mapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
				arrays[attributeId] = this;
				if(!array)
					exception("Failed to create array buffer");
			}
			float* array = null;
			uint globj = 0;
			uint size;
			uint attributeId;
			/*~this(){
				glDeleteBuffers(1, &globj);
			}*/
		}
		
		Array[uint] arrays;
	
		void add(uint target, float[] data){
			if(target !in arrays)
				arrays[target] = new Array(data.length.to!uint, target);
			float* o = arrays[target].array+currentVert*data.length;
			o[0..data.length] = data;
		}

}
