module ws.draw;


class DrawEmpty {

	void destroy(){assert(false, "not implemented");}

	void resize(int[2] size){assert(false, "not implemented");}

	void setColor(float[3] color){assert(false, "not implemented");}
	void setColor(float[4] color){assert(false, "not implemented");}
	void setColor(int color){
		if(color > 0xFFFFFF)
			setColor(
					[(color>>24)/255.0f,
					((color>>16)&0xFF)/255.0f,
					((color>>8)&0xFF)/255.0f,
					(color&0xFF)/255.0f]
				);
		else
			setColor(
					[(color>>16)/255.0f,
					((color>>8)&0xFF)/255.0f,
					(color&0xFF)/255.0f]
				);
	}

	void clip(int[2] pos, int[2] size){assert(false, "not implemented");}
	void noclip(){assert(false, "not implemented");}

	void rect(int[2] pos, int[2] size){assert(false, "not implemented");}

	void rectOutline(int[2] pos, int[2] size){assert(false, "not implemented");}

	void line(int[2] start, int[2] end){assert(false, "not implemented");}

	void setFont(string font, int size){assert(false, "not implemented");}

	int fontHeight(){assert(false, "not implemented");}

	int text(int[2] pos, string text, double offset=-1){assert(false, "not implemented");}
	
	int text(int[2] pos, int h, string text, double offset=-0.2){assert(false, "not implemented");}

	int width(string text){assert(false, "not implemented");}

	void finishFrame(){assert(false, "not implemented");}

}
