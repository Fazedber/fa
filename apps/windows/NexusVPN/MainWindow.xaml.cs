using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using System;
using System.Threading;
using Windows.UI;

namespace NexusVPN
{
    public sealed partial class MainWindow : Window
    {
        private CoreBridge _bridge;
        private CancellationTokenSource _cts;

        public MainWindow()
        {
            this.InitializeComponent();
            
            // Activate Windows 11 Mica Glassmorphism material for the App window
            this.SystemBackdrop = new MicaBackdrop(); 

#if PEPE
            this.Title = "PepeWatafa";
#else
            this.Title = "Nebula";
#endif

            // Initialize gRPC Bridge to Go Backend
            _bridge = new CoreBridge();
            _bridge.OnStateChanged += Bridge_OnStateChanged;
            
            _cts = new CancellationTokenSource();
            // Start listening in background to State Machine Stream
            _ = _bridge.ListenToStateAsync(_cts.Token);
        }

        private async void ConnectBtn_Click(object sender, RoutedEventArgs e)
        {
            if (BtnText.Text == "CONNECT")
            {
                // UI does NOT implement VPN logic, it just sends the request to the Go Service
                await _bridge.ConnectAsync("default-profile");
            }
            else
            {
                await _bridge.DisconnectAsync();
            }
        }

        private void Bridge_OnStateChanged(string newState)
        {
            // Thread safely update UI (gRPC runs on background thread)
            DispatcherQueue.TryEnqueue(() =>
            {
                StatusText.Text = $"STATUS: {newState}";
                
                if (newState == "CONNECTED")
                {
                    BtnText.Text = "DISCONNECT";
                    // Transition to Neon Cyan glowing effect (Glassmorphism)
                    GlowBorder.Background = new SolidColorBrush(Color.FromArgb(100, 0, 255, 204));
                    StatusText.Foreground = new SolidColorBrush(Color.FromArgb(255, 0, 255, 204));
                }
                else if (newState == "CONNECTING" || newState == "RECONNECTING")
                {
                    BtnText.Text = "CONNECTING...";
                    // Orange glow for trying to connect
                    GlowBorder.Background = new SolidColorBrush(Color.FromArgb(100, 255, 170, 0)); 
                }
                else
                {
                    BtnText.Text = "CONNECT";
                    // Reset to unlit state
                    GlowBorder.Background = new SolidColorBrush(Color.FromArgb(50, 68, 68, 68));
                    StatusText.Foreground = new SolidColorBrush(Colors.DarkGray);
                }
            });
        }
    }
}
