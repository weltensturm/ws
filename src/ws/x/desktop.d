module ws.x.desktop;


import
	std.file,
	std.algorithm,
	std.array,
	std.path,
	std.regex,
	std.stdio,
	std.string;


const string[] desktopPaths = [
	"/usr",
	"/usr/local",
	"~/.local"
];


class DesktopEntry {

	string exec;
	string type;
	string name;
	string comment;
	string terminal;
	string[] categories;

	this(string text){
		bool validSection;
		foreach(line; text.splitLines){
			if(line.startsWith("["))
				validSection = line == "[Desktop Entry]";
			else if(validSection && line.startsWith("Exec="))
				exec = line.chompPrefix("Exec=");
			else if(validSection && line.startsWith("Name="))
				name = line.chompPrefix("Name=");
			else if(validSection && line.startsWith("Categories="))
				categories = line.chompPrefix("Categories=").split(";").filter!"a.length".array;
		}
	}

}

DesktopEntry[] readDesktop(string path){
	DesktopEntry[] result;
	if(!path.isFile)
		return result;
	foreach(section; matchAll(path.readText, `\[[^\]\r\n]+\](?:\r?\n(?:[^\[\r\n].*)?)*`)){
		result ~= new DesktopEntry(section.hit);
	}
	return result;
}

DesktopEntry[] getAll(){
	DesktopEntry[] result;
	foreach(path; desktopPaths){
		if((path.expandTilde~"/share/applications").exists)
			foreach(entry; (path.expandTilde~"/share/applications").dirEntries(SpanMode.breadth))
				try
					result ~= readDesktop(entry);
				catch(Throwable t)
					writeln("DESKTOP_ERROR %s: %s".format(entry, t));
	}
	return result;
}

