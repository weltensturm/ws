module ws.gl.render;

import
	ws.gl.gl,
	ws.gl.batch,
	ws.gl.shader,
	ws.math.vector,
	ws.math.matrix;


class Render {

	this(Matrix!(4,4) delegate() getMvp){
		this.getMvp = getMvp;
		lineBatch = new Batch;
		lineBatch.begin(2, gl.lines);
		lineBatch.add([0,0,0]);
		lineBatch.add([1,1,1]);
		lineBatch.finish();
		lineShader = Shader.load("3d_line", gl.attributeVertex, "vertex");
	}

	void line(Vector!3 from, Vector!3 to){
		lineShader.use(
			"matMVP", getMvp(),
			"offset", from ~ 0.5, // TODO: find out why
			"scale", (to - from) ~ 0.5,
			"color", m_color
		);
		lineBatch.draw();
	}

	@property
	float[4] color(){
		return m_color;
	}
	
	@property
	void color(float[4] c){
		m_color = c;
	}

	protected {
		float[4] m_color;
		Shader lineShader;
		Batch lineBatch;
		Matrix!(4,4) delegate() getMvp;
	}

}