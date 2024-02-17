using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace NesCompiler
{
    class Program
    {
        public const string templateFilename = "../../NesTemplates/gametemplate.asm";
        public const string defaultCharset = "../../NesTemplates/defaultchar.chr";
        public static void Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.WriteLine("Error: input file expected. Default will be used");
                try
                {
                    Compile("../../Default.den", templateFilename);
                }
                catch(Exception ex)
                {
                    Console.WriteLine("Error: " + ex.Message);
                }
            }
            else
            {
                Compile(args[0], templateFilename);
            }

            Console.ReadKey();
        }

        static void Compile(string filename, string templateFilename)
        {
            var text = File.ReadAllText(filename);

            var inputWithoutExtension = Path.GetFileNameWithoutExtension(filename);

            var lexer = new Lexer(text);
            var tokens = lexer.Process();

            foreach(var token in tokens)
            {
                Console.WriteLine("token: " + token.Type + "; " + token.Value);
            }

            try
            {
                var parser = new Parser(tokens);
                var ast = parser.Parse();

                Console.WriteLine("ast tree: ");
                parser.PrintAst(ast, 0);
                Console.WriteLine("end of ast tree;\n");

                
                var codeGenerator = new CodeGenerator(ast, templateFilename);
                var assembly = codeGenerator.Generate();
                Console.WriteLine("assembly code:");
                
                Console.WriteLine(assembly);

                string[] files = Directory.GetFiles("../../NesOutput");
                foreach (string file in files)
                {
                    File.Delete(file);
                }

                File.Copy(defaultCharset, "../../NesOutput/defaultchar.chr");

                var assemblyFilename = "../../NesOutput/" + inputWithoutExtension + ".asm";

                File.WriteAllText(assemblyFilename, assembly);
                Console.WriteLine("Created " + assemblyFilename);

                string batRelativeFileName = "../../NesTools/generate_nes.bat";
                string currentDirectory = Directory.GetCurrentDirectory();
                string batFullPath = Path.GetFullPath(Path.Combine(currentDirectory, batRelativeFileName));
                Console.WriteLine("bat full path: " + batFullPath);

                string absoluteAssemblyFilename = Path.GetFullPath(Path.Combine(currentDirectory, assemblyFilename));
                Console.WriteLine("absoluteAssemblyFilename: " + absoluteAssemblyFilename);
                string argument = absoluteAssemblyFilename;

                Process process = new Process();
                process.StartInfo.FileName = "\"" + batFullPath + "\"";
                process.StartInfo.Arguments = "\"" + argument + "\"";
                //process.StartInfo.RedirectStandardError = true;
                //process.StartInfo.UseShellExecute = false;

                string command = process.StartInfo.FileName + " " + process.StartInfo.Arguments;
                Console.WriteLine(command);

                process.Start();

                //Console.WriteLine(process.StandardError.ReadToEnd());


            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
        }
    }
}
