using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;

namespace NexusVPN
{
    public partial class MainWindow : Window
    {
        private readonly CoreBridge _bridge;
        private readonly CancellationTokenSource _cts;
        private readonly string _brandKey;
        private readonly string _brandDisplay;
        private readonly ShellStateStore _stateStore;
        private readonly GitHubReleaseUpdater _releaseUpdater;
        private readonly SolidColorBrush _paperInkBrush = new(Color.FromRgb(0xF4, 0xEF, 0xE8));
        private readonly SolidColorBrush _emberBrush = new(Color.FromRgb(0xD8, 0xB4, 0x63));
        private readonly SolidColorBrush _jadeBrush = new(Color.FromRgb(0x7C, 0xD7, 0xC0));
        private readonly SolidColorBrush _roseBrush = new(Color.FromRgb(0xD8, 0x7A, 0x8A));
        private ShellState _shellState;
        private ReleaseUpdateInfo? _pendingUpdate;

        public MainWindow()
        {
            InitializeComponent();

#if PEPE
            _brandKey = "pepewatafa";
            _brandDisplay = "PepeWatafa";
            Title = "PepeWatafa VPN";
            BrandTitle.Text = "PepeWatafa VPN";
#else
            _brandKey = "nebula";
            _brandDisplay = "Nebula";
            Title = "Nebula VPN";
            BrandTitle.Text = "Nebula VPN";
#endif

            _bridge = new CoreBridge();
            _bridge.OnStateChanged += Bridge_OnStateChanged;
            _cts = new CancellationTokenSource();
            _stateStore = new ShellStateStore(_brandKey);
            _shellState = _stateStore.Load();
            _releaseUpdater = new GitHubReleaseUpdater(_brandDisplay);

            Loaded += MainWindow_Loaded;
            Closed += MainWindow_Closed;
        }

        private async void MainWindow_Loaded(object sender, RoutedEventArgs e)
        {
            ApplyShellState();
            _ = _bridge.ListenToStateAsync(_cts.Token);
            await CheckForUpdatesAsync(silent: true);
        }

        private void MainWindow_Closed(object? sender, EventArgs e)
        {
            _cts.Cancel();
            _cts.Dispose();
        }

        private async void ConnectBtn_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrWhiteSpace(_shellState.ProfileId))
            {
                StatusText.Text = "STATUS: IMPORT A VLESS OR HYSTERIA2 LINK FIRST";
                StateGlyphText.Text = "WAITING";
                ModeText.Text = "UNBOUND";
                ProfileInputBox.Focus();
                return;
            }

            ConnectBtn.IsEnabled = false;
            try
            {
                if (BtnText.Text == "CONNECT" || BtnText.Text == "RETRY")
                {
                    StateGlyphText.Text = "INVOCATION";
                    StatusText.Text = "STATUS: OPENING TUNNEL";
                    ProtocolText.Text = "HANDSHAKE";
                    await _bridge.ConnectAsync(_shellState.ProfileId);
                }
                else if (BtnText.Text == "DISCONNECT")
                {
                    StateGlyphText.Text = "SEALING";
                    StatusText.Text = "STATUS: CLOSING TUNNEL";
                    await _bridge.DisconnectAsync();
                }
            }
            catch (Exception ex)
            {
                ApplyFaultState(ex.Message);
            }
            finally
            {
                ConnectBtn.IsEnabled = true;
            }
        }

        private void PasteBtn_Click(object sender, RoutedEventArgs e)
        {
            if (Clipboard.ContainsText())
            {
                ProfileInputBox.Text = Clipboard.GetText().Trim();
            }

            ProfileInputBox.Focus();
            ProfileInputBox.SelectAll();
        }

        private async void ImportBtn_Click(object sender, RoutedEventArgs e)
        {
            var payload = ProfileInputBox.Text.Trim();
            if (string.IsNullOrWhiteSpace(payload) && Clipboard.ContainsText())
            {
                payload = Clipboard.GetText().Trim();
                ProfileInputBox.Text = payload;
            }

            if (string.IsNullOrWhiteSpace(payload))
            {
                StatusText.Text = "STATUS: PASTE A VLESS:// OR HYSTERIA2:// LINK";
                return;
            }

            ImportBtn.IsEnabled = false;
            try
            {
                StatusText.Text = "STATUS: IMPORTING PROXY LINK";
                var profileId = await _bridge.ImportConfigAsync(payload);
                var profile = ImportedProfileInfo.Parse(payload, profileId);

                _shellState.ProfileId = profileId;
                _shellState.ProfileName = profile.Name;
                _shellState.RouteLabel = profile.RouteLabel;
                _shellState.Protocol = profile.Protocol;
                _shellState.LastImportPayload = payload;
                SaveShellState();

                ApplyShellState();
                ModeText.Text = "BOUND";
                StateGlyphText.Text = "ARMED";
                StatusText.Text = $"STATUS: PROFILE {profile.Name.ToUpperInvariant()} READY";
            }
            catch (Exception ex)
            {
                ApplyFaultState(ex.Message);
            }
            finally
            {
                ImportBtn.IsEnabled = true;
            }
        }

        private async void UpdateBtn_Click(object sender, RoutedEventArgs e)
        {
            UpdateBtn.IsEnabled = false;
            try
            {
                if (_pendingUpdate?.IsAvailable == true)
                {
                    await DownloadAndInstallUpdateAsync(_pendingUpdate);
                }
                else
                {
                    await CheckForUpdatesAsync(silent: false);
                }
            }
            catch (OperationCanceledException)
            {
            }
            catch (Exception ex)
            {
                UpdateStatusText.Text = $"UPDATE CHANNEL: {ex.Message.ToUpperInvariant()}";
                UpdateBtn.Content = "CHECK UPDATES";
            }
            finally
            {
                UpdateBtn.IsEnabled = true;
            }
        }

        private void Bridge_OnStateChanged(string newState)
        {
            Dispatcher.Invoke(() => ApplyState(newState));
        }

        private void ApplyState(string newState)
        {
            StatusText.Text = $"STATUS: {newState}";

            if (newState == "CONNECTED")
            {
                BtnText.Text = "DISCONNECT";
                ModeText.Text = "ASCENDANT";
                StateGlyphText.Text = "OPEN";
                ProtocolText.Text = GetConfiguredProtocolLabel();
                GlowBorder.Fill = new SolidColorBrush(Color.FromRgb(0x11, 0x1E, 0x1B));
                GlowBorder.Stroke = _jadeBrush;
                ConnectBtn.BorderBrush = _jadeBrush;
                ConnectBtn.Foreground = _paperInkBrush;
                HeroGlyph.Foreground = _jadeBrush;
                StatusText.Foreground = _paperInkBrush;
            }
            else if (newState == "CONNECTING" || newState == "RECONNECTING")
            {
                BtnText.Text = "SEAL";
                ModeText.Text = "TRANSIT";
                StateGlyphText.Text = "RISING";
                ProtocolText.Text = "HANDSHAKE";
                GlowBorder.Fill = new SolidColorBrush(Color.FromRgb(0x1D, 0x17, 0x0E));
                GlowBorder.Stroke = _emberBrush;
                ConnectBtn.BorderBrush = _emberBrush;
                ConnectBtn.Foreground = _paperInkBrush;
                HeroGlyph.Foreground = _emberBrush;
                StatusText.Foreground = _paperInkBrush;
            }
            else if (newState.StartsWith("ERROR", StringComparison.OrdinalIgnoreCase))
            {
                ApplyFaultState(newState);
            }
            else
            {
                BtnText.Text = "CONNECT";
                ModeText.Text = string.IsNullOrWhiteSpace(_shellState.ProfileId) ? "UNBOUND" : "RITUAL";
                StateGlyphText.Text = string.IsNullOrWhiteSpace(_shellState.ProfileId) ? "WAITING" : "DORMANT";
                ProtocolText.Text = GetConfiguredProtocolLabel();
                GlowBorder.Fill = new SolidColorBrush(Color.FromRgb(0x0A, 0x0A, 0x0D));
                GlowBorder.Stroke = _emberBrush;
                ConnectBtn.BorderBrush = _emberBrush;
                ConnectBtn.Foreground = _paperInkBrush;
                HeroGlyph.Foreground = new SolidColorBrush(Color.FromRgb(0x12, 0x12, 0x12));
                StatusText.Foreground = _paperInkBrush;
            }

            if (newState.Contains("UNAVAILABLE", StringComparison.OrdinalIgnoreCase))
            {
                RouteText.Text = "OFFLINE";
            }
            else
            {
                RouteText.Text = GetConfiguredRouteLabel();
            }
        }

        private void ApplyShellState()
        {
            ProfileInputBox.Text = _shellState.LastImportPayload ?? string.Empty;
            RouteText.Text = GetConfiguredRouteLabel();
            ProtocolText.Text = GetConfiguredProtocolLabel();

            if (string.IsNullOrWhiteSpace(_shellState.ProfileId))
            {
                ModeText.Text = "UNBOUND";
                StateGlyphText.Text = "WAITING";
                ProfileSummaryText.Text = "No proxy link imported yet.";
                StatusText.Text = "STATUS: IMPORT A LINK TO ARM THE TUNNEL";
                return;
            }

            ModeText.Text = "RITUAL";
            StateGlyphText.Text = "DORMANT";
            ProfileSummaryText.Text = BuildProfileSummary();
            StatusText.Text = $"STATUS: PROFILE {_shellState.ProfileName?.ToUpperInvariant() ?? "IMPORTED"} LOADED";
        }

        private string GetConfiguredRouteLabel()
        {
            return string.IsNullOrWhiteSpace(_shellState.RouteLabel) ? "NO LINK" : _shellState.RouteLabel!;
        }

        private string GetConfiguredProtocolLabel()
        {
            return string.IsNullOrWhiteSpace(_shellState.Protocol) ? "WAITING" : _shellState.Protocol!;
        }

        private string BuildProfileSummary()
        {
            var builder = new StringBuilder("Bound profile: ");
            builder.Append(string.IsNullOrWhiteSpace(_shellState.ProfileName) ? "Imported Node" : _shellState.ProfileName);

            if (!string.IsNullOrWhiteSpace(_shellState.RouteLabel))
            {
                builder.Append(" / ");
                builder.Append(_shellState.RouteLabel);
            }

            if (!string.IsNullOrWhiteSpace(_shellState.Protocol))
            {
                builder.Append(" / ");
                builder.Append(_shellState.Protocol);
            }

            return builder.ToString();
        }

        private void ApplyFaultState(string message)
        {
            BtnText.Text = "RETRY";
            ModeText.Text = "FAULT";
            StateGlyphText.Text = "BROKEN";
            ProtocolText.Text = "UNSTABLE";
            GlowBorder.Fill = new SolidColorBrush(Color.FromRgb(0x18, 0x0D, 0x11));
            GlowBorder.Stroke = _roseBrush;
            ConnectBtn.BorderBrush = _roseBrush;
            ConnectBtn.Foreground = _paperInkBrush;
            HeroGlyph.Foreground = new SolidColorBrush(Color.FromRgb(0xE0, 0x8C, 0x9A));
            StatusText.Text = $"STATUS: {message.ToUpperInvariant()}";
            StatusText.Foreground = _paperInkBrush;
        }

        private void SaveShellState()
        {
            _stateStore.Save(_shellState);
        }

        private async Task CheckForUpdatesAsync(bool silent)
        {
            UpdateStatusText.Text = silent
                ? "UPDATE CHANNEL: SYNCING WITH GITHUB RELEASES"
                : "UPDATE CHANNEL: CHECKING GITHUB RELEASES";

            try
            {
                _pendingUpdate = await _releaseUpdater.CheckForUpdateAsync(_cts.Token);
                if (_pendingUpdate is null)
                {
                    UpdateStatusText.Text = "UPDATE CHANNEL: FEED RETURNED NO VERSION DATA";
                    UpdateBtn.Content = "CHECK UPDATES";
                    return;
                }

                if (_pendingUpdate.IsAvailable)
                {
                    UpdateStatusText.Text = $"UPDATE CHANNEL: {_pendingUpdate.DisplayVersion} READY TO INSTALL";
                    UpdateBtn.Content = $"INSTALL {_pendingUpdate.DisplayVersion}";
                }
                else
                {
                    UpdateStatusText.Text = $"UPDATE CHANNEL: {_pendingUpdate.DisplayVersion} IS ALREADY INSTALLED";
                    UpdateBtn.Content = "CHECK UPDATES";
                }
            }
            catch (OperationCanceledException)
            {
            }
            catch (Exception ex)
            {
                if (!silent)
                {
                    UpdateStatusText.Text = $"UPDATE CHANNEL: {ex.Message.ToUpperInvariant()}";
                }
                else
                {
                    UpdateStatusText.Text = "UPDATE CHANNEL: OFFLINE, RETRY MANUALLY";
                }

                UpdateBtn.Content = "CHECK UPDATES";
            }
        }

        private async Task DownloadAndInstallUpdateAsync(ReleaseUpdateInfo updateInfo)
        {
            var result = MessageBox.Show(
                $"{updateInfo.DisplayVersion} is available from GitHub Releases. Download the new installer and hand off to it now?",
                $"{_brandDisplay} VPN Update",
                MessageBoxButton.YesNo,
                MessageBoxImage.Question);

            if (result != MessageBoxResult.Yes)
            {
                return;
            }

            UpdateStatusText.Text = $"UPDATE CHANNEL: DOWNLOADING {updateInfo.DisplayVersion}";
            var installerPath = await _releaseUpdater.DownloadInstallerAsync(updateInfo, _cts.Token);
            UpdateStatusText.Text = $"UPDATE CHANNEL: HANDING OFF {Path.GetFileName(installerPath)}";

            Process.Start(new ProcessStartInfo
            {
                FileName = installerPath,
                UseShellExecute = true
            });

            Application.Current.Shutdown();
        }

        private sealed class ImportedProfileInfo
        {
            public string Name { get; init; } = "Imported Node";
            public string RouteLabel { get; init; } = "NO LINK";
            public string Protocol { get; init; } = "WAITING";

            public static ImportedProfileInfo Parse(string payload, string profileId)
            {
                var trimmed = payload.Trim();
                if (!Uri.TryCreate(trimmed, UriKind.Absolute, out var uri))
                {
                    return new ImportedProfileInfo
                    {
                        Name = profileId,
                        RouteLabel = "IMPORTED",
                        Protocol = "UNKNOWN"
                    };
                }

                var name = Uri.UnescapeDataString(uri.Fragment.TrimStart('#'));
                if (string.IsNullOrWhiteSpace(name))
                {
                    name = uri.Host;
                }

                var route = uri.Host;
                if (string.IsNullOrWhiteSpace(route))
                {
                    route = "IMPORTED";
                }

                return new ImportedProfileInfo
                {
                    Name = name,
                    RouteLabel = route.ToUpperInvariant(),
                    Protocol = uri.Scheme.ToUpperInvariant()
                };
            }
        }
    }
}
