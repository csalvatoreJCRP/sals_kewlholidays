// cwconv: CodeWalker XML (as Sollumz writes it) -> binary game files.
//   cwconv <in.ydr.xml|in.ytyp.xml|in.ytd.xml|in.ybn.xml> <out file>
// Textures referenced by a .ydr.xml are read from the XML's folder.
using System;
using System.IO;
using System.Xml;
using CodeWalker.GameFiles;

class Program
{
    static int Main(string[] args)
    {
        if (args.Length < 2) { Console.Error.WriteLine("usage: cwconv <in.xml> <out>"); return 2; }
        var inPath = Path.GetFullPath(args[0]);
        var outPath = Path.GetFullPath(args[1]);
        var folder = Path.GetDirectoryName(inPath);
        var doc = new XmlDocument();
        doc.Load(inPath);
        byte[] data;
        var low = inPath.ToLowerInvariant();
        if (low.EndsWith(".ydr.xml")) data = XmlMeta.GetYdrData(doc, folder);
        else if (low.EndsWith(".ytd.xml")) data = XmlMeta.GetYtdData(doc, folder);
        else if (low.EndsWith(".ybn.xml")) data = XmlMeta.GetYbnData(doc);
        else if (low.EndsWith(".ytyp.xml")) data = XmlMeta.GetData(doc, MetaFormat.RSC, inPath);
        else { Console.Error.WriteLine("unknown extension: " + inPath); return 2; }
        if (data == null) { Console.Error.WriteLine("conversion produced nothing for " + inPath); return 1; }
        File.WriteAllBytes(outPath, data);
        Console.WriteLine($"{Path.GetFileName(outPath)}  {data.Length} bytes");
        return 0;
    }
}
