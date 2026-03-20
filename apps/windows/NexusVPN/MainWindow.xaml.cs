using System;
using System.Threading;
using System.Windows;
using System.Windows.Media;

namespace NexusVPN
{
    public partial class MainWindow : Window
    {
        private readonly CoreBridge _bridge;
        private readonly CancellationTokenSource _cts;
        private readonly SolidColorBrush _paperInkBrush = new(Color.FromRgb(0xF4, 0xEF, 0xE8));
        private readonly SolidColorBrush _emberBrush = new(Color.FromRgb(0xD8, 0xB4, 0x63));
        private readonly SolidColorBrush _jadeBrush = new(Color.FromRgb(0x7C, 0xD7, 0xC0));

        public MainWindow()
        {
            InitializeComponent();

#if PEPE
            Title = "PepeWatafa";
            BrandTitle.Text = "PepeWatafa VPN";
            RouteText.Text = "SEOUL-07";
#else
            Title = "Nebula";
            BrandTitle.Text = "Nebula VPN";
            RouteText.Text = "TOKYO-01";
#endif

            _bridge = new CoreBridge();
            _bridge.OnStateChanged += Bridge_OnStateChanged;
            _cts = new CancellationTokenSource();

            Loaded += MainWindow_Loaded;
            Closed += MainWindow_Closed;
        }

        private void MainWindow_Loaded(object sender, RoutedEventArgs e)
        {
            _ = _bridge.ListenToStateAsync(_cts.Token);
        }

        private void MainWindow_Closed(object? sender, EventArgs e)
        {
            _cts.Cancel();
            _cts.Dispose();
        }

        private async void ConnectBtn_Click(object sender, RoutedEventArgs e)
        {
            ConnectBtn.IsEnabled = false;
            try
            {
                if (BtnText.Text == "CONNECT")
                {
                    StateGlyphText.Text = "INVOCATION";
                    StatusText.Text = "STATUS: OPENING TUNNEL";
                    await _bridge.ConnectAsync("default-profile");
                }
                else if (BtnText.Text == "DISCONNECT")
                {
                    StateGlyphText.Text = "SEALING";
                    StatusText.Text = "STATUS: CLOSING TUNNEL";
                    await _bridge.DisconnectAsync();
                }
            }
            finally
            {
                ConnectBtn.IsEnabled = true;
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
                ProtocolText.Text = "VLESS";
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
                BtnText.Text = "RETRY";
                ModeText.Text = "FAULT";
                StateGlyphText.Text = "BROKEN";
                ProtocolText.Text = "UNSTABLE";
                var roseBrush = new SolidColorBrush(Color.FromRgb(0xD8, 0x7A, 0x8A));
                GlowBorder.Fill = new SolidColorBrush(Color.FromRgb(0x18, 0x0D, 0x11));
                GlowBorder.Stroke = roseBrush;
                ConnectBtn.BorderBrush = roseBrush;
                ConnectBtn.Foreground = _paperInkBrush;
                HeroGlyph.Foreground = new SolidColorBrush(Color.FromRgb(0xE0, 0x8C, 0x9A));
                StatusText.Foreground = _paperInkBrush;
            }
            else
            {
                BtnText.Text = "CONNECT";
                ModeText.Text = "RITUAL";
                StateGlyphText.Text = "DORMANT";
                ProtocolText.Text = "VLESS";
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
            else if (newState == "CONNECTED")
            {
#if PEPE
                RouteText.Text = "SEOUL-07";
#else
                RouteText.Text = "TOKYO-01";
#endif
            }
        }
    }
}
