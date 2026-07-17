module ws.x.desktop;


import
	std.file,
	std.algorithm,
	std.array,
	std.process,
	std.path,
	std.regex,
	std.stdio,
	std.string;


string[] desktopPaths(){
	return
		["~/.local/share".expandTilde]
		~ environment.get("XDG_DATA_DIRS").split(':');
}

auto EXEC_REGEX = ctRegex!`\[[^\]\r\n]+\](?:\r?\n(?:[^\[\r\n].*)?)*`;

class DesktopEntry {

	string path;
	string exec;
	string type;
	string name;
	string comment;
	string terminal;
	string[] categories;
	string[] onlyShowInDesktop;
	bool noDisplay;

	this(string path, string text){
		bool validSection;
		this.path = path;
		foreach(line; text.splitLines){
			if(line.startsWith("["))
				validSection = line == "[Desktop Entry]";
			else if(validSection && line.startsWith("Exec="))
				exec = line.chompPrefix("Exec=");
			else if(validSection && line.startsWith("Name="))
				name = line.chompPrefix("Name=");
			else if(validSection && line.startsWith("Categories="))
				categories = line.chompPrefix("Categories=").split(";").filter!"a.length".array;
			else if(validSection && line.startsWith("NoDisplay="))
				noDisplay = line.canFind("true");
			else if(validSection && line.startsWith("OnlyShowIn="))
				onlyShowInDesktop = line.chompPrefix("OnlyShowIn=").split(';');
		}
	}

}

DesktopEntry[] readDesktop(string path){
	DesktopEntry[] result;
	if(!path.isFile)
		return result;
	foreach(section; matchAll(path.readText, EXEC_REGEX)){
		result ~= new DesktopEntry(path, section.hit);
	}
	return result;
}

DesktopEntry[] getAll(){
	DesktopEntry[] result;
	foreach(path; desktopPaths){
		if((buildPath(path, "applications")).exists){
			foreach(entry; buildPath(path, "applications").dirEntries(SpanMode.breadth))
				try
					result ~= readDesktop(entry);
				catch(FileException e){}
				catch(Throwable t)
					writeln("DESKTOP_ERROR %s: %s".format(entry, t));
		}
	}
	return result;
}

