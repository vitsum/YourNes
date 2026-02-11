using System;
using System.Diagnostics;
using System.IO;

namespace NesCompiler
{
    class Program
    {
        public const string TemplateFilename = "NesTemplates/gametemplate.asm";
        public const string DefaultCharset = "NesTemplates/defaultchar.chr";

        public static void Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.WriteLine("Error: input file expected. Default will be used");
                try
                {
                    Compile("examples/Default.den", TemplateFilename);
                }
                catch (Exception ex)
                {
                    Console.WriteLine("Error: " + ex.Message);
                }
            }
            else
            {
                Compile(args[0], TemplateFilename);
            }
        }

        static void Compile(string filename, string templateFilename)
        {
            var text = File.ReadAllText(filename);
            var inputWithoutExtension = Path.GetFileNameWithoutExtension(filename);

            var lexer = new Lexer(text);
            var tokens = lexer.Process();

            foreach (var token in tokens)
                Console.WriteLine($"token: {token.Type}; {token.Value}");

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

                string outputDir = "NesOutput";
                Directory.CreateDirectory(outputDir);

                foreach (string file in Directory.GetFiles(outputDir))
                    File.Delete(file);

                File.Copy(DefaultCharset, Path.Combine(outputDir, "defaultchar.chr"));

                var assemblyFilename = Path.Combine(outputDir, inputWithoutExtension + ".asm");
                File.WriteAllText(assemblyFilename, assembly);
                Console.WriteLine("Created " + assemblyFilename);

                string batRelativeFileName = "NesTools/generate_nes.bat";
                string currentDirectory = Directory.GetCurrentDirectory();
                string batFullPath = Path.GetFullPath(Path.Combine(currentDirectory, batRelativeFileName));
                string absoluteAssemblyFilename = Path.GetFullPath(Path.Combine(currentDirectory, assemblyFilename));

                Console.WriteLine("bat full path: " + batFullPath);
                Console.WriteLine("absoluteAssemblyFilename: " + absoluteAssemblyFilename);

                var process = new Process();
                process.StartInfo.FileName = "\"" + batFullPath + "\"";
                process.StartInfo.Arguments = "\"" + absoluteAssemblyFilename + "\"";
                process.StartInfo.RedirectStandardError = true;
                process.StartInfo.UseShellExecute = false;

                Console.WriteLine(process.StartInfo.FileName + " " + process.StartInfo.Arguments);

                process.Start();
                process.WaitForExit();

                string errors = process.StandardError.ReadToEnd();
                if (!string.IsNullOrEmpty(errors))
                    Console.WriteLine("Batch Script Errors:\n" + errors);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
        }
    }
}
