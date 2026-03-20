using System;
using System.IO;
using System.Text.Json;

namespace NexusVPN
{
    public sealed class ShellState
    {
        public string? ProfileId { get; set; }
        public string? ProfileName { get; set; }
        public string? RouteLabel { get; set; }
        public string? Protocol { get; set; }
        public string? LastImportPayload { get; set; }
        public string? IgnoredReleaseVersion { get; set; }
    }

    public sealed class ShellStateStore
    {
        private static readonly JsonSerializerOptions SerializerOptions = new()
        {
            WriteIndented = true
        };

        private readonly string _filePath;

        public ShellStateStore(string brandKey)
        {
            var root = Path.Combine(
                Environment.GetEnvironmentVariable("LOCALAPPDATA") ?? Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "NexusVPN");

            _filePath = Path.Combine(root, $"{brandKey.ToLowerInvariant()}-shell-state.json");
        }

        public ShellState Load()
        {
            try
            {
                if (!File.Exists(_filePath))
                {
                    return new ShellState();
                }

                var json = File.ReadAllText(_filePath);
                return JsonSerializer.Deserialize<ShellState>(json) ?? new ShellState();
            }
            catch
            {
                return new ShellState();
            }
        }

        public void Save(ShellState state)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(_filePath)!);

            var tempPath = _filePath + ".tmp";
            var json = JsonSerializer.Serialize(state, SerializerOptions);

            File.WriteAllText(tempPath, json);
            File.Move(tempPath, _filePath, true);
        }
    }
}
