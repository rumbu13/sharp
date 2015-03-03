using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace genunicode
{
    class MyWriter: BinaryWriter
    {
        public MyWriter(Stream stream) : base(stream)
        {
            
        }
        public void write7bit(int value)
        {
            Write7BitEncodedInt(value);
        }
    }
    
    class Program
    {

        

        static List<Tuple<uint, uint, UnicodeCategory>> ranges = new List<Tuple<uint, uint, UnicodeCategory>>();
        
        const string sourceFile = "unicodedata.txt";
        //const string destFile = "..\\..\\..\\src\\system\\internals\\unicodedata.d";
        const string destFile = "..\\..\\..\\res\\unicodedata.bin";
        const string url = "http://www.unicode.org/Public/UNIDATA/UnicodeData.txt";
        static void Main(string[] args)
        {
            var cults = CultureInfo.GetCultures(CultureTypes.AllCultures);
            foreach (var cult in cults.OrderBy(c => c.LCID))
                if (cult.TextInfo.IsRightToLeft)
                    Console.WriteLine("0x{0:X4}", cult.LCID);
            Console.ReadLine();
            return;

            bool mustDownload = true;
            if (File.Exists(sourceFile))
            {
                mustDownload = false;
                DateTime fileDate = File.GetLastWriteTime(sourceFile);
                if ((DateTime.Now - fileDate).TotalDays > 30)
                    mustDownload = true;
            }

            if (mustDownload)
            {
                Console.WriteLine("Downloading...");
                using (WebClient Client = new WebClient())
                {
                    Client.DownloadFile(url, sourceFile);
                }
            }

            string[] lines = File.ReadAllLines(sourceFile);

            Console.WriteLine("Processing...");
            List<Tuple<uint, UnicodeCategory>> codes = new List<Tuple<uint, UnicodeCategory>>();
            List<Tuple<uint, string>> values = new List<Tuple<uint, string>>();
            List<Tuple<uint, sbyte, sbyte>> decimals = new List<Tuple<uint, sbyte, sbyte>>();
            List<Tuple<uint, uint>> lowercase = new List<Tuple<uint, uint>>();
            List<Tuple<uint, uint>> uppercase = new List<Tuple<uint, uint>>();
            List<Tuple<uint, uint>> titlecase = new List<Tuple<uint, uint>>();

            foreach (var line in lines)
            {
                string[] items = line.Split(';');
                uint code = uint.Parse(items[0], NumberStyles.HexNumber);
                UnicodeCategory c = UnicodeCategory.PrivateUse;
                switch (items[2])
                {
                    case "Cc": c = UnicodeCategory.Control; break;
                    case "Cf": c = UnicodeCategory.Format; break;
                    case "Cn": c = UnicodeCategory.OtherNotAssigned; break;
                    case "Co": c = UnicodeCategory.PrivateUse; break;
                    case "Cs": c = UnicodeCategory.Surrogate; break;
                    case "Ll": c = UnicodeCategory.LowercaseLetter; break;
                    case "Lm": c = UnicodeCategory.ModifierLetter; break;
                    case "Lo": c = UnicodeCategory.OtherLetter; break;
                    case "Lt": c = UnicodeCategory.TitlecaseLetter; break;
                    case "Lu": c = UnicodeCategory.UppercaseLetter; break;
                    case "Mc": c = UnicodeCategory.SpacingCombiningMark; break;
                    case "Me": c = UnicodeCategory.EnclosingMark; break;
                    case "Mn": c = UnicodeCategory.NonSpacingMark; break;
                    case "Nd": c = UnicodeCategory.DecimalDigitNumber; break;
                    case "Nl": c = UnicodeCategory.LetterNumber; break;
                    case "No": c = UnicodeCategory.OtherNumber; break;
                    case "Pc": c = UnicodeCategory.ConnectorPunctuation; break;
                    case "Pd": c = UnicodeCategory.DashPunctuation; break;
                    case "Pe": c = UnicodeCategory.ClosePunctuation; break;
                    case "Pf": c = UnicodeCategory.FinalQuotePunctuation; break;
                    case "Pi": c = UnicodeCategory.InitialQuotePunctuation; break;
                    case "Po": c = UnicodeCategory.OtherPunctuation; break;
                    case "Ps": c = UnicodeCategory.OpenPunctuation; break;
                    case "Sc": c = UnicodeCategory.CurrencySymbol; break;
                    case "Sk": c = UnicodeCategory.ModifierSymbol; break;
                    case "Sm": c = UnicodeCategory.MathSymbol; break;
                    case "So": c = UnicodeCategory.OtherSymbol; break;
                    case "Zl": c = UnicodeCategory.LineSeparator; break;
                    case "Zp": c = UnicodeCategory.ParagraphSeparator; break;
                    case "Zs": c = UnicodeCategory.SpaceSeparator; break;
                    default: break;
                }
                codes.Add(new Tuple<uint, UnicodeCategory>(code, c));
                
                if (!String.IsNullOrEmpty(items[8]))
                {
                    values.Add(new Tuple<uint, string>(code, items[8]));
                }
                bool hasDecimal = false;
                bool hasDigit = false;
                sbyte dec = -1;
                sbyte digit = -1;

                if (!String.IsNullOrEmpty(items[6]))
                    hasDecimal = sbyte.TryParse(items[6], NumberStyles.Integer, CultureInfo.InvariantCulture, out dec);

                if (!String.IsNullOrEmpty(items[7]))
                    hasDigit = sbyte.TryParse(items[6], NumberStyles.Integer, CultureInfo.InvariantCulture, out digit);

                if (hasDecimal || hasDigit)
                    decimals.Add(new Tuple<uint, sbyte, sbyte>(code, dec, digit));

                if (!String.IsNullOrEmpty(items[12]))
                    uppercase.Add(new Tuple<uint, uint>(code, uint.Parse(items[12], NumberStyles.HexNumber, CultureInfo.InvariantCulture)));
                if (!String.IsNullOrEmpty(items[13]))
                    lowercase.Add(new Tuple<uint, uint>(code, uint.Parse(items[13], NumberStyles.HexNumber, CultureInfo.InvariantCulture)));
                if (!String.IsNullOrEmpty(items[14]))
                    titlecase.Add(new Tuple<uint, uint>(code, uint.Parse(items[14], NumberStyles.HexNumber, CultureInfo.InvariantCulture)));

            }
            Console.WriteLine("Optimizing...");
            codes = codes.OrderBy(i => i.Item1).ToList();

            
            uint tcode = codes[0].Item1;
            UnicodeCategory tcateg = codes[0].Item2;
            Tuple<uint, UnicodeCategory> previous = codes[0];
            for (int i = 1; i < codes.Count; i++)
            {
                if (previous.Item2 != codes[i].Item2)
                {
                    ranges.Add(new Tuple<uint, uint, UnicodeCategory>(tcode, codes[i].Item1 - 1, tcateg));
                    tcode = codes[i].Item1;
                    tcateg = codes[i].Item2;
                    previous = codes[i];
                }
            }
            ranges.Add(new Tuple<uint, uint, UnicodeCategory>(previous.Item1 + 1, codes[codes.Count - 1].Item1, codes[codes.Count - 1].Item2));

            var uniques = ranges.Where(t => t.Item1 > 255 && t.Item1 == t.Item2).Select(t => new Tuple<uint, UnicodeCategory>(t.Item1, t.Item3)).ToList();

            var ranges2 = ranges.Where(t => t.Item1 > 255 && t.Item1 != t.Item2).ToList();
            //1195 ranges, 1715 uniques

            var shortRanges = ranges2.Where(r => r.Item2 < 65536);
            var uintRanges = ranges2.Where(r => r.Item1 >= 65536);
            var shortPoints = uniques.Where(u => u.Item1 < 65536);
            var uintPoints = uniques.Where(u => u.Item1 >= 65536);

            var uptitlecase = from u in uppercase join t in titlecase on u.Item1 equals t.Item1 select new Tuple<uint, uint, uint>(u.Item1, u.Item2, t.Item2);

            var stream = File.Create(destFile);
            MyWriter writer = new MyWriter(stream);

            for (int x = 0; x <= 255; x++)
            {
                var item = ranges.First(t => x >= t.Item1 && x <= t.Item2);
                writer.Write((byte)item.Item3);
            }

            writer.Write(ranges2.Count());
            foreach (var x in ranges2)
            {
                writer.write7bit((int)x.Item1);
                writer.write7bit((int)x.Item2);
                writer.Write((byte)x.Item3);
            }


            //writer.Write(shortRanges.Count());
            //foreach (var x in shortRanges)
            //{
            //    writer.write7bit((ushort)x.Item1);
            //    writer.write7bit((ushort)x.Item2);
            //    writer.Write((byte)x.Item3);
            //}

            //writer.Write(uintRanges.Count());
            //foreach (var x in uintRanges)
            //{
            //    writer.write7bit((int)x.Item1);
            //    writer.write7bit((int)x.Item2);
            //    writer.Write((byte)x.Item3);
            //}

            writer.Write(uniques.Count());
            foreach (var y in uniques)
            {
                writer.write7bit((int)y.Item1);
                writer.Write((byte)y.Item2);
            }

            //writer.Write(shortPoints.Count());
            //foreach (var y in shortPoints)
            //{
            //    writer.write7bit((ushort)y.Item1);
            //    writer.Write((byte)y.Item2);
            //}

            //writer.Write(uintPoints.Count());
            //foreach (var y in uintPoints)
            //{
            //    writer.write7bit((int)y.Item1);
            //    writer.Write((byte)y.Item2);
            //}

            writer.Write(values.Count());
            foreach (var y in values)
            {
                writer.write7bit((int)y.Item1);
                double d;
                if (!double.TryParse(y.Item2, out d))
                {
                    int p = y.Item2.IndexOf("/");
                    d = double.Parse(y.Item2.Substring(0, p));
                    d = d / double.Parse(y.Item2.Substring(p + 1));
                }
                writer.Write(d);
            }

            writer.Write(decimals.Count());
            foreach (var y in decimals)
            {
                writer.write7bit((int)y.Item1);
                writer.Write(y.Item2);
                writer.Write(y.Item3);
            }

            writer.Write(lowercase.Count());
            foreach (var y in lowercase)
            {
                writer.write7bit((int)y.Item1);
                writer.write7bit((int)y.Item2);
            }

            var upUnique = uptitlecase.Where(u => u.Item2 == u.Item3);
            var upDouble = uptitlecase.Where(u => u.Item2 != u.Item3);

            writer.Write(upUnique.Count());
            foreach (var y in upUnique)
            {
                writer.write7bit((int)y.Item1);
                writer.write7bit((int)y.Item2);
            }

            writer.Write(upDouble.Count());
            foreach (var y in upDouble)
            {
                writer.write7bit((int)y.Item1);
                writer.write7bit((int)y.Item2);
                writer.write7bit((int)y.Item3);
            }

            

            //StringBuilder sb = new StringBuilder();
            //sb.AppendLine("module system.internals.unicodedata;");
            //sb.AppendLine();
            //sb.AppendLine("private pure @safe nothrow @nogc:");
            //sb.AppendLine();

            //sb.AppendLine(  "enum latinCount      = 256;");
            //sb.AppendFormat("enum shortRangeCount = {0};\r\n", shortRanges.Count());
            //sb.AppendFormat("enum uintRangeCount  = {0};\r\n", uintRanges.Count());
            //sb.AppendFormat("enum shortPointCount = {0};\r\n", shortPoints.Count());
            //sb.AppendFormat("enum uintPointCount  = {0};\r\n", uintPoints.Count());
            //sb.AppendFormat("enum valueCount      = {0};\r\n", values.Count());
            //sb.AppendFormat("enum decimalCount    = {0};\r\n", decimals.Count());

            //sb.AppendLine();

            //sb.AppendLine("struct SR");
            //sb.AppendLine("{");
            //sb.AppendLine("    ushort from;");
            //sb.AppendLine("    ushort to;");
            //sb.AppendLine("    ubyte category;");
            //sb.AppendLine("}");

            //sb.AppendLine();

            //sb.AppendLine("struct UR");
            //sb.AppendLine("{");
            //sb.AppendLine("    uint from;");
            //sb.AppendLine("    uint to;");
            //sb.AppendLine("    ubyte category;");
            //sb.AppendLine("}");

            //sb.AppendLine();

            //sb.AppendLine("struct SP");
            //sb.AppendLine("{");
            //sb.AppendLine("    ushort code;");
            //sb.AppendLine("    ubyte category;");
            //sb.AppendLine("}");

            //sb.AppendLine();

            //sb.AppendLine("struct UP");
            //sb.AppendLine("{");
            //sb.AppendLine("    uint code;");
            //sb.AppendLine("    ubyte category;");
            //sb.AppendLine("}");

            //sb.AppendLine();

            //sb.AppendLine("struct UV");
            //sb.AppendLine("{");
            //sb.AppendLine("    uint code;");
            //sb.AppendLine("    double value;");
            //sb.AppendLine("}");

            //sb.AppendLine();

            //sb.AppendLine("struct UD");
            //sb.AppendLine("{");
            //sb.AppendLine("    uint code;");
            //sb.AppendLine("    byte decimal;");
            //sb.AppendLine("    byte digit;");
            //sb.AppendLine("}");

            //sb.AppendLine();

            //sb.Append("immutable ubyte[latinCount] latinmap = [");
            //for (int x = 0; x <= 255; x++)
            //{
            //    if (x % 16 == 0)
            //        sb.Append("\r\n    ");
            //    else
            //        sb.Append(" ");
            //    var item = ranges.First(t => x >= t.Item1 && x <= t.Item2);
            //    sb.AppendFormat("{0,2},", (byte)item.Item3);
            //}

            

            //sb.AppendLine();
            //sb.AppendLine("];");

            //sb.AppendLine();

            //sb.AppendLine("immutable SR[shortRangeCount] shortRanges = [");
            //int l = 0;
            //foreach (var x in shortRanges)
            //{
            //    if (l % 5 == 0)
            //        sb.Append("    ");
            //    else
            //        sb.Append(" ");
            //    sb.AppendFormat("SR(0x{0:x4}, 0x{1:x4}, {2,2}),", x.Item1, x.Item2, (byte)x.Item3);
            //    l++;
            //    if (l % 5 == 0)
            //        sb.AppendLine();
            //}
            

            //sb.AppendLine();
            //sb.AppendLine("];");

            //sb.AppendLine();

            //sb.AppendLine("immutable UR[uintRangeCount] uintRanges = [");
            //l = 0;
            //foreach (var x in uintRanges)
            //{
            //    if (l % 4 == 0)
            //        sb.Append("    ");
            //    else
            //        sb.Append(" ");
            //    sb.AppendFormat("UR(0x{0:x6}, 0x{1:x6}, {2,2}),", x.Item1, x.Item2, (byte)x.Item3);
            //    l++;
            //    if (l % 4 == 0)
            //        sb.AppendLine();
            //}

            

            //sb.AppendLine();
            //sb.AppendLine("];");

            //sb.AppendLine();

            //sb.AppendLine();
            //sb.AppendLine("immutable SP[shortPointCount] shortPoints = [");
            //l = 0;
            //foreach (var y in shortPoints)
            //{
            //    if (l % 7 == 0)
            //        sb.Append("    ");
            //    else
            //        sb.Append(" ");
            //    sb.AppendFormat("SP(0x{0:x4}, {1,2}),", y.Item1, (byte)y.Item2);
            //    l++;
            //    if (l % 7 == 0)
            //        sb.AppendLine();
            //}
            //sb.AppendLine("];");

            

            //sb.AppendLine();

            //sb.AppendLine();
            //sb.AppendLine("immutable UP[uintPointCount] uintPoints = [");
            //l = 0;
            //foreach (var y in uintPoints)
            //{
            //    if (l % 6 == 0)
            //        sb.Append("    ");
            //    else
            //        sb.Append(" ");
            //    sb.AppendFormat("UP(0x{0:x6}, {1,2}),", y.Item1, (byte)y.Item2);
            //    l++;
            //    if (l % 6 == 0)
            //        sb.AppendLine();
            //}
            //sb.AppendLine("];");

            

            //sb.AppendLine();

            //sb.AppendLine("immutable UV[valueCount] values = [");
            //l = 0;
            //foreach (var y in values)
            //{
            //    if (l % 4 == 0)
            //        sb.Append("    ");
            //    else
            //        sb.Append(" ");
            //    sb.AppendFormat(CultureInfo.InvariantCulture, "UV(0x{0:x6}, {1,13}),", y.Item1, y.Item2);
            //    l++;
            //    if (l % 4 == 0)
            //        sb.AppendLine();
            //}
            //sb.AppendLine();
            //sb.AppendLine("];");

            //sb.AppendLine();

            //sb.AppendLine("immutable UD[decimalCount] decimals = [");
            //l = 0;
            //foreach (var y in decimals)
            //{
            //    if (l % 6 == 0)
            //        sb.Append("    ");
            //    else
            //        sb.Append(" ");
            //    sb.AppendFormat(CultureInfo.InvariantCulture, "UD(0x{0:x6},{1,2},{2,2}),", y.Item1, y.Item2, y.Item3);
            //    l++;
            //    if (l % 6 == 0)
            //        sb.AppendLine();
            //}
            //sb.AppendLine("];");

           

            //sb.AppendLine();


            //sb.AppendLine("public ubyte getLatinCategory(in ubyte code)");
            //sb.AppendLine("{");
            //sb.AppendLine("    return latinmap[code];");
            //sb.AppendLine("}");

            //sb.AppendLine();

            //sb.AppendLine("public ubyte getShortCategory(in ushort code)");
            //sb.AppendLine("{");
            //sb.AppendLine("    assert(code > ubyte.max);");
            //sb.AppendLine("    for(size_t i = 0; i < shortRangeCount; i++)");
            //sb.AppendLine("        if (code >= shortRanges[i].from && code <= shortRanges[i].to)");
            //sb.AppendLine("            return shortRanges[i].category;");
            //sb.AppendLine("        else if (shortRanges[i].from > code)");
            //sb.AppendLine("            break;");
            //sb.AppendLine("    for(size_t i = 0; i < shortPointCount; i++)");
            //sb.AppendLine("        if (shortPoints[i].code == code)");
            //sb.AppendLine("            return shortPoints[i].category;");
            //sb.AppendLine("        else if (shortPoints[i].code > code)");
            //sb.AppendLine("            break;");
            //sb.AppendLine("    return 0x1d;");
            //sb.AppendLine("}");

            //sb.AppendLine();

            //sb.AppendLine("public ubyte getUintCategory(in uint code)");
            //sb.AppendLine("{");
            //sb.AppendLine("    assert(code > ushort.max);");
            //sb.AppendLine("    for(size_t i = 0; i < uintRangeCount; i++)");
            //sb.AppendLine("        if (code >= uintRanges[i].from && code <= uintRanges[i].to)");
            //sb.AppendLine("            return uintRanges[i].category;");
            //sb.AppendLine("        else if (shortRanges[i].from > code)");
            //sb.AppendLine("            break;");
            //sb.AppendLine("    for(size_t i = 0; i < uintPointCount; i++)");
            //sb.AppendLine("        if (uintPoints[i].code == code)");
            //sb.AppendLine("            return uintPoints[i].category;");
            //sb.AppendLine("        else if (uintPoints[i].code > code)");
            //sb.AppendLine("            break;");
            //sb.AppendLine("    return 0x1d;");
            //sb.AppendLine("}");

            //sb.AppendLine("public double getValue(in uint code)");
            //sb.AppendLine("{");
            //sb.AppendLine("    for(size_t i = 0; i < valueCount; i++)");
            //sb.AppendLine("        if (values[i].code == code)");
            //sb.AppendLine("            return values[i].value;");
            //sb.AppendLine("        else if (values[i].code > code)");
            //sb.AppendLine("            break;");
            //sb.AppendLine("    return -1;");
            //sb.AppendLine("}");

            //sb.AppendLine("public byte getDecimalDigit(in uint code)");
            //sb.AppendLine("{");
            //sb.AppendLine("    for(size_t i = 0; i < decimalCount; i++)");
            //sb.AppendLine("        if (decimals[i].code == code)");
            //sb.AppendLine("            return decimals[i].decimal;");
            //sb.AppendLine("        else if (decimals[i].code > code)");
            //sb.AppendLine("            break;");
            //sb.AppendLine("    return -1;");
            //sb.AppendLine("}");

            //sb.AppendLine();

            //sb.AppendLine("public byte getDigitValue(in uint code)");
            //sb.AppendLine("{");
            //sb.AppendLine("    for(size_t i = 0; i < decimalCount; i++)");
            //sb.AppendLine("        if (decimals[i].code == code)");
            //sb.AppendLine("            return decimals[i].digit;");
            //sb.AppendLine("        else if (decimals[i].code > code)");
            //sb.AppendLine("            break;");
            //sb.AppendLine("    return -1;");
            //sb.AppendLine("}");

            //sb.AppendLine();

            //File.WriteAllText(destFile, sb.ToString());
            stream.Close();
            Console.WriteLine("Done.");
            Console.ReadKey();
        }
    }
}
