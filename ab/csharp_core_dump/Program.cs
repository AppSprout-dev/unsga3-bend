using System.Globalization;
using System.Text.Json;
using Unsga3.Algorithm;
using Unsga3.Operators.Survival;
using Unsga3.Utilities;

/// <summary>
/// One-shot dump of C# NondominatedSortingSurvival.Select (rng == null)
/// on the same objective fixture as the Bend v0 A/B path. Not a NuGet
/// package. ProjectReference comes from MSBuild Unsga3Project
/// ($UNSGA3_CS_ROOT/src/Unsga3/Unsga3.csproj). This tree does not vendor Unsga3.
/// </summary>
internal static class Program
{
    public static int Main(string[] args)
    {
        string? fixture = null;
        string? output = null;
        for (int i = 0; i < args.Length; i++)
        {
            if (args[i] == "--fixture" && i + 1 < args.Length)
                fixture = args[++i];
            else if (args[i] == "--out" && i + 1 < args.Length)
                output = args[++i];
        }

        if (string.IsNullOrWhiteSpace(fixture) || string.IsNullOrWhiteSpace(output))
        {
            Console.Error.WriteLine("usage: csharp_core_dump --fixture FILE --out FILE");
            return 2;
        }

        if (!File.Exists(fixture))
        {
            Console.Error.WriteLine($"missing fixture: {fixture}");
            return 2;
        }

        using var doc = JsonDocument.Parse(File.ReadAllText(fixture));
        var root = doc.RootElement;
        int nObj = root.GetProperty("n_obj").GetInt32();
        int partitions = root.GetProperty("partitions").GetInt32();
        int target = root.GetProperty("target_size").GetInt32();
        var pop = new List<Individual>();
        foreach (var row in root.GetProperty("objectives").EnumerateArray())
        {
            var ind = new Individual(Math.Max(1, nObj), nObj);
            int j = 0;
            foreach (var v in row.EnumerateArray())
            {
                if (j < nObj)
                    ind.Objectives[j++] = v.GetDouble();
            }

            pop.Add(ind);
        }

        var dirs = ReferenceDirections.DasDennis(nObj, partitions);
        var survival = new NondominatedSortingSurvival(new ReferencePointManager(dirs));
        var selected = survival.Select(pop, target, rng: null);

        var dest = Path.GetFullPath(output);
        var dir = Path.GetDirectoryName(dest);
        if (!string.IsNullOrEmpty(dir))
            Directory.CreateDirectory(dir);

        using var writer = new StreamWriter(dest);
        foreach (var ind in selected)
        {
            for (int j = 0; j < ind.Objectives.Length; j++)
            {
                if (j > 0)
                    writer.Write(',');
                writer.Write(ind.Objectives[j].ToString("G17", CultureInfo.InvariantCulture));
            }

            writer.WriteLine();
        }

        return 0;
    }
}
