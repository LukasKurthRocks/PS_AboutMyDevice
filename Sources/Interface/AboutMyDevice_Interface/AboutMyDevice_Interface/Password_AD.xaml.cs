using MahApps.Metro.Controls;
using MahApps.Metro.Theming;
using ControlzEx.Theming;
using System;
using System.Collections.Generic;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Threading;

namespace AboutMyDevice_Interface {
    /// <summary>
    /// Interaktionslogik für Password_AD.xaml
    /// </summary>
    public partial class Password_AD : MetroWindow {

        private DispatcherTimer _timer;

        public Password_AD() {
            InitializeComponent();

            //ThemeManager.Current.ChangeTheme(this, "Dark.Red");
        }

        private void MainWindow_Loaded(object sender, RoutedEventArgs e) {
            _timer = new DispatcherTimer(TimeSpan.FromMilliseconds(200),
                DispatcherPriority.Normal,
                (o, args) => {
                    //this.theProgressBar.Value = DateTime.Now.Millisecond;
                    //theOtherProgressBar.Value = DateTime.Now.Millisecond;
                },
                Dispatcher);
            _timer.Start();
        }

        private void MainWindow_Unloaded(object sender, RoutedEventArgs e) {
            _timer?.Stop();
        }

        private MetroWindow accentThemeTestWindow;

        private void ChangeAppStyleButtonClick(object sender, RoutedEventArgs e) {
            if (accentThemeTestWindow != null) {
                accentThemeTestWindow.Activate();
                return;
            }

            accentThemeTestWindow = new AccentStyleWindow();
            accentThemeTestWindow.Owner = this;
            accentThemeTestWindow.Closed += (o, args) => accentThemeTestWindow = null;
            accentThemeTestWindow.Left = this.Left + this.ActualWidth / 2.0;
            accentThemeTestWindow.Top = this.Top + this.ActualHeight / 2.0;
            accentThemeTestWindow.Show();
        }

        private void Click_ChangeTheme(object sender, RoutedEventArgs e) {
            //ThemeManager.Current.ChangeTheme(this, "Dark.Green");
            ThemeManager.Current.ThemeSyncMode = ThemeSyncMode.SyncWithAppMode;
            ThemeManager.Current.SyncTheme();
        }
    }
}
