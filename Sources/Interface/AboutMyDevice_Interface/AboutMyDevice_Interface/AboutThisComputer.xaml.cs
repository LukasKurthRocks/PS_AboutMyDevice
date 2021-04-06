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
using MahApps.Metro.Controls;

namespace AboutMyDevice_Interface {
    /// <summary>
    /// Interaktionslogik für AboutThisComputer.xaml
    /// </summary>
    public partial class AboutThisComputer : MetroWindow {
        public AboutThisComputer() {
            InitializeComponent();
        }
        private void ToggleSwitch_Toggled(object sender, RoutedEventArgs e) {
            ToggleSwitch toggleSwitch = sender as ToggleSwitch;
            if (toggleSwitch != null) {
                if (toggleSwitch.IsOn == true) {
                    //progress.IsActive = true;
                    //progress.Visibility = Visibility.Visible;
                } else {
                    //progress.IsActive = false;
                    //progress.Visibility = Visibility.Collapsed;
                }
            }
        }

        private void Click_LaunchGitHubSite(object sender, RoutedEventArgs e) {

        }

        private void Click_OpenAdminPanel(object sender, RoutedEventArgs e) {

        }

        private MetroWindow accentThemeTestWindow;

        private void Click_ChangeAppStyleButtonClick(object sender, RoutedEventArgs e) {
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
    }
}
