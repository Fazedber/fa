using System;
using System.IO;
using System.Net.Http;
using System.Reflection;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace NexusVPN
{
    public sealed class ReleaseUpdateInfo
    {
        public ReleaseUpdateInfo(
            Version currentVersion,
            Version latestVersion,
            string tagName,
            string? installerName,
            string? installerUrl,
            string? releaseUrl)
        {
            CurrentVersion = currentVersion;
            LatestVersion = latestVersion;
            TagName = tagName;
            InstallerName = installerName;
            InstallerUrl = installerUrl;
            ReleaseUrl = releaseUrl;
        }

        public Version CurrentVersion { get; }
        public Version LatestVersion { get; }
        public string TagName { get; }
        public string? InstallerName { get; }
        public string? InstallerUrl { get; }
        public string? ReleaseUrl { get; }
        public bool IsAvailable => LatestVersion > CurrentVersion && !string.IsNullOrWhiteSpace(InstallerUrl);
        public string DisplayVersion => TagName.StartsWith("v", StringComparison.OrdinalIgnoreCase) ? TagName : $"v{LatestVersion}";
    }

    public sealed class GitHubReleaseUpdater
    {
        private const string LatestReleaseUrl = "https://api.github.com/repos/Fazedber/fa/releases/latest";
        private static readonly HttpClient Client = CreateClient();

        private readonly string _brand;
        private readonly string _downloadDirectory;

        public GitHubReleaseUpdater(string brand)
        {
            _brand = brand;
            _downloadDirectory = Path.Combine(
                Environment.GetEnvironmentVariable("LOCALAPPDATA") ?? Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "NexusVPN",
                "updates");
        }

        public Version GetCurrentVersion()
        {
            var entryAssembly = Assembly.GetEntryAssembly();
            return entryAssembly?.GetName().Version ?? new Version(0, 0, 0, 0);
        }

        public async Task<ReleaseUpdateInfo?> CheckForUpdateAsync(CancellationToken cancellationToken)
        {
            using var response = await Client.GetAsync(LatestReleaseUrl, cancellationToken);
            response.EnsureSuccessStatusCode();

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);

            var root = document.RootElement;
            var tagName = root.GetProperty("tag_name").GetString();
            if (!TryParseVersion(tagName, out var latestVersion))
            {
                return null;
            }

            string? releaseUrl = null;
            if (root.TryGetProperty("html_url", out var htmlUrlElement))
            {
                releaseUrl = htmlUrlElement.GetString();
            }

            string? installerName = null;
            string? installerUrl = null;

            if (root.TryGetProperty("assets", out var assetsElement) && assetsElement.ValueKind == JsonValueKind.Array)
            {
                foreach (var asset in assetsElement.EnumerateArray())
                {
                    if (!asset.TryGetProperty("name", out var nameElement) ||
                        !asset.TryGetProperty("browser_download_url", out var urlElement))
                    {
                        continue;
                    }

                    var assetName = nameElement.GetString();
                    if (string.IsNullOrWhiteSpace(assetName))
                    {
                        continue;
                    }

                    if (!assetName.StartsWith($"{_brand}-VPN-", StringComparison.OrdinalIgnoreCase) ||
                        !assetName.EndsWith("-Setup.exe", StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }

                    installerName = assetName;
                    installerUrl = urlElement.GetString();
                    break;
                }
            }

            return new ReleaseUpdateInfo(GetCurrentVersion(), latestVersion, tagName ?? latestVersion.ToString(), installerName, installerUrl, releaseUrl);
        }

        public async Task<string> DownloadInstallerAsync(ReleaseUpdateInfo updateInfo, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(updateInfo.InstallerUrl) || string.IsNullOrWhiteSpace(updateInfo.InstallerName))
            {
                throw new InvalidOperationException("Windows installer asset is not available for this release.");
            }

            Directory.CreateDirectory(_downloadDirectory);

            var destinationPath = Path.Combine(_downloadDirectory, updateInfo.InstallerName);
            using var response = await Client.GetAsync(updateInfo.InstallerUrl, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
            response.EnsureSuccessStatusCode();

            await using var source = await response.Content.ReadAsStreamAsync(cancellationToken);
            await using var target = File.Create(destinationPath);
            await source.CopyToAsync(target, cancellationToken);

            return destinationPath;
        }

        private static HttpClient CreateClient()
        {
            var client = new HttpClient
            {
                Timeout = TimeSpan.FromSeconds(20)
            };

            client.DefaultRequestHeaders.UserAgent.ParseAdd("NexusVPN-Windows/1.0");
            client.DefaultRequestHeaders.Accept.ParseAdd("application/vnd.github+json");

            return client;
        }

        private static bool TryParseVersion(string? rawValue, out Version version)
        {
            version = new Version(0, 0, 0, 0);
            if (string.IsNullOrWhiteSpace(rawValue))
            {
                return false;
            }

            var normalized = rawValue.Trim();
            if (normalized.StartsWith("v", StringComparison.OrdinalIgnoreCase))
            {
                normalized = normalized[1..];
            }

            var separatorIndex = normalized.IndexOfAny(['-', '+']);
            if (separatorIndex >= 0)
            {
                normalized = normalized[..separatorIndex];
            }

            if (!Version.TryParse(normalized, out var parsedVersion))
            {
                return false;
            }

            version = parsedVersion;
            return true;
        }
    }
}
