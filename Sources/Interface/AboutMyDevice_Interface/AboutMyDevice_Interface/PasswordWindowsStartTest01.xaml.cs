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
using MahApps.Metro;
using MahApps.Metro.Controls;

namespace AboutMyDevice_Interface {
    /// <summary>
    /// Interaktionslogik für PasswordWindowsStartTest01.xaml
    /// </summary>
    public partial class PasswordWindowsStartTest01 : MetroWindow {
        public PasswordWindowsStartTest01() {
            InitializeComponent();
        }

        public string resultValue;

        private MetroWindow authenticationWindow;

        private void Click_OpenPasswordBox(object sender, RoutedEventArgs e) {
            if (authenticationWindow != null) {
                authenticationWindow.Activate();
                return;
            }

            authenticationWindow = new Password_AD_NoPwCount(); // (this) when coded parent
            authenticationWindow.Owner = this;
            authenticationWindow.Closed += (o, args) => authenticationWindow = null;
            authenticationWindow.Left = this.Left + this.ActualWidth / 2.0;
            authenticationWindow.Top = this.Top + this.ActualHeight / 2.0;
            
            if(authenticationWindow.ShowDialog().Value) {
                lblStatus.Content = "Successful?" + resultValue;
            } else {
                lblStatus.Content = "Not Successful??";
            }
        }

        private void Click_LaunchGitHubSite(object sender, RoutedEventArgs e) {
            // TODO
        }
    }
}
