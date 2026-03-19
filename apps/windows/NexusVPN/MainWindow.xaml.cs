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

        public MainWindow()
        {
            InitializeComponent();

#if PEPE
            Title = "PepeWatafa VPN";
            BrandTitle.Text = "PepeWatafa VPN";
#else
            Title = "Nebula VPN";
            BrandTitle.Text = "Nebula VPN";
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
                    await _bridge.ConnectAsync("default-profile");
                }
                else if (BtnText.Text == "DISCONNECT")
                {
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
            Dispatcher.Invoke(() =>
            {
                StatusText.Text = $"STATUS: {newState}";

                if (newState == "CONNECTED")
                {
                    BtnText.Text = "DISCONNECT";
                    GlowBorder.Background = new SolidColorBrush(Color.FromArgb(0x4D, 0x00, 0xD4, 0xAA));
                    GlowBorder.BorderBrush = new SolidColorBrush(Color.FromArgb(0x99, 0x00, 0xFF, 0xCC));
                    StatusText.Foreground = new SolidColorBrush(Color.FromRgb(0x63, 0xF0, 0xD1));
                }
                else if (newState == "CONNECTING" || newState == "RECONNECTING")
                {
                    BtnText.Text = "CONNECTING";
                    GlowBorder.Background = new SolidColorBrush(Color.FromArgb(0x4D, 0xFF, 0x8A, 0x00));
                    GlowBorder.BorderBrush = new SolidColorBrush(Color.FromArgb(0x99, 0xFF, 0xB3, 0x33));
                    StatusText.Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0xC9, 0x66));
                }
                else
                {
                    BtnText.Text = "CONNECT";
                    GlowBorder.Background = new SolidColorBrush(Color.FromArgb(0x20, 0x35, 0x44, 0x66));
                    GlowBorder.BorderBrush = new SolidColorBrush(Color.FromArgb(0x40, 0xA7, 0xE5, 0xFF));
                    StatusText.Foreground = new SolidColorBrush(Color.FromRgb(0xA0, 0xAB, 0xB9));
                }
            });
        }
    }
}
